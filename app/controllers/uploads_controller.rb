class UploadsController < ApplicationController
  before_action :require_login
  before_action :set_project
  before_action :set_upload, only: %i[show download]

  MAX_FILES_PER_BATCH = 10

  def show; end

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

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_upload
    @upload = @project.uploads.find(params[:id])
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
end
