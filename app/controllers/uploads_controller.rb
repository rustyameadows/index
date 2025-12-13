class UploadsController < ApplicationController
  before_action :require_login
  before_action :set_project
  before_action :set_upload, only: %i[show download enhance]
  before_action :set_derived_uploads, only: :show
  before_action :set_enhancement_options, only: :show

  MAX_FILES_PER_BATCH = 10
  ENHANCERS = { topaz: "Topaz Labs" }.freeze
  ENHANCEABLE_CONTENT_TYPES = %w[image/jpeg image/jpg image/pjpeg image/png image/tiff image/tif].freeze
  MAX_AUTH_STRENGTH = 0.5
  MAX_AUTH_DENOISE = 0.25
  MAX_AUTH_SHARPEN = 0.25
  MAX_AUTH_FIX_COMPRESSION = 0.3

  def show
    @entities = @project.entities.order(:name)
    @linked_entities = @upload.entities.order(:name)
    @available_entities = @entities.where.not(id: @linked_entities.pluck(:id))
  end

  def create
    files = upload_params[:files]&.reject(&:blank?) || []

    if files.empty?
      return redirect_to project_path(@project), alert: "Please choose at least one file to upload."
    end

    if files.size > MAX_FILES_PER_BATCH
      return redirect_to project_path(@project), alert: "You can upload up to #{MAX_FILES_PER_BATCH} files at once."
    end

    successes = []
    failures = []

    files.each do |file|
      upload = @project.uploads.build(user: current_user)
      attach_file_and_metadata(upload, file)

      if upload.save
        successes << upload
      else
        failures << "#{file.original_filename || 'file'}: #{upload.errors.full_messages.to_sentence}"
      end
    end

    if failures.empty?
      redirect_to project_path(@project), notice: "#{successes.size} file#{'s' if successes.size != 1} uploaded."
    elsif successes.any?
      redirect_to project_path(@project), alert: "Uploaded #{successes.size} file#{'s' if successes.size != 1}; #{failures.size} failed: #{failures.join('; ')}"
    else
      @uploads = @project.uploads.order(created_at: :desc).includes(file_attachment: :blob)
      flash.now[:alert] = "No files uploaded: #{failures.join('; ')}"
      render "projects/show", status: :unprocessable_entity
    end
  end

  def download
    if @upload.file.attached?
      redirect_to rails_blob_url(@upload.file, disposition: "attachment")
    else
      redirect_to project_path(@project), alert: "File not found."
    end
  end

  def enhance
    provider = (params[:provider] || :topaz).to_sym
    settings = build_settings(provider)

    unless ENHANCERS.key?(provider)
      return redirect_to project_upload_path(@project, @upload), alert: "Choose a valid provider."
    end

    unless @upload.image?
      return redirect_to project_upload_path(@project, @upload), alert: "Only image uploads can be enhanced."
    end

    unless enhanceable_type?(@upload)
      return redirect_to project_upload_path(@project, @upload), alert: "This file type isn't supported for enhancement (Topaz accepts JPEG, PNG, or TIFF)."
    end

    ImageEnhancementJob.perform_later(@upload.id, provider: provider, settings: settings)
    redirect_to project_upload_path(@project, @upload), notice: "Enhancement queued with #{ENHANCERS[provider]}."
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_upload
    @upload = @project.uploads.find(params[:id])
  end

  def set_derived_uploads
    @derived_uploads = @upload.derived_uploads.includes(file_attachment: :blob).order(created_at: :desc)
  end

  def upload_params
    params.require(:upload).permit(files: [])
  end

  def attach_file_and_metadata(upload, file_param)
    return unless file_param && file_param.respond_to?(:original_filename)

    upload.file.attach(file_param)
    upload.original_filename = file_param.original_filename
    upload.content_type = file_param.content_type
    upload.byte_size = file_param.size
    upload.uploaded_at = Time.current
  end

  # Enhancement flow
  def set_enhancement_options
    @enhancement_providers = ENHANCERS
  end

  def build_settings(provider)
    return parse_settings_json(params[:settings]) unless provider == :topaz

    topaz_params = params.fetch(:topaz, {}).to_unsafe_h
    preset = (topaz_params[:preset] || "preserve").to_s
    settings = topaz_preset_settings(preset)
    authenticity_lock = topaz_params[:authenticity_lock] == "1"

    overrides = {
      strength: topaz_params[:strength],
      denoise: topaz_params[:denoise],
      sharpen: topaz_params[:sharpen],
      fix_compression: topaz_params[:fix_compression],
      output_width: topaz_params[:output_width],
      output_height: topaz_params[:output_height],
      face_enhancement: topaz_params[:face_enhancement] == "1",
      face_enhancement_strength: topaz_params[:face_enhancement_strength],
      face_enhancement_creativity: topaz_params[:face_enhancement_creativity]
    }.compact_blank

    float_keys = %i[strength denoise sharpen fix_compression face_enhancement_strength face_enhancement_creativity].freeze
    int_keys = %i[output_width output_height].freeze

    overrides.each do |key, val|
      next if val.blank?

      settings[key] =
        if float_keys.include?(key)
          val.to_f
        elsif int_keys.include?(key)
          val.to_i
        else
          val
        end
    end

    settings = apply_authenticity_lock(settings) if authenticity_lock
    settings.compact
  end

  def topaz_preset_settings(preset)
    case preset
    when "preserve"
      { model: "High Fidelity V2", strength: 0.4, denoise: 0.2, sharpen: 0.15, fix_compression: 0.2, face_enhancement: true, face_enhancement_strength: 0.5, face_enhancement_creativity: 0.0 }
    when "low_res_assist"
      { model: "Standard V2", strength: 0.45, denoise: 0.25, sharpen: 0.15, fix_compression: 0.25, face_enhancement: true, face_enhancement_strength: 0.5, face_enhancement_creativity: 0.0 }
    when "sharpen_mild"
      { model: "Standard V2", strength: 0.3, denoise: 0.1, sharpen: 0.25, fix_compression: 0.1, face_enhancement: false }
    when "recovery_experimental"
      # Topaz "Recovery V2" is a generative model and not allowed under the Enhance/GAN endpoint.
      # Use Standard V2 with stronger settings as a safer fallback.
      { model: "Standard V2", strength: 0.55, denoise: 0.25, sharpen: 0.2, fix_compression: 0.2, face_enhancement: true, face_enhancement_strength: 0.45, face_enhancement_creativity: 0.0, experimental: true }
    else
      {}
    end
  end

  def apply_authenticity_lock(settings)
    settings.merge(
      strength: clamp(settings[:strength], 0, MAX_AUTH_STRENGTH),
      denoise: clamp(settings[:denoise], 0, MAX_AUTH_DENOISE),
      sharpen: clamp(settings[:sharpen], 0, MAX_AUTH_SHARPEN),
      fix_compression: clamp(settings[:fix_compression], 0, MAX_AUTH_FIX_COMPRESSION),
      face_enhancement_creativity: clamp(settings[:face_enhancement_creativity], 0, 0.0) # force 0
    ).compact
  end

  def clamp(val, min, max)
    return val if val.nil?

    [[val.to_f, min].max, max].min
  end

  def parse_settings_json(settings_param)
    return {} if settings_param.blank?

    JSON.parse(settings_param)
  rescue JSON::ParserError
    {}
  end

  def enhanceable_type?(upload)
    ct = upload.file&.content_type&.downcase
    ENHANCEABLE_CONTENT_TYPES.include?(ct)
  end
end
