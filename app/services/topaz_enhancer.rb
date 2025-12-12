require "net/http"
require "uri"
require "json"
require "tempfile"
require "securerandom"
require "digest"

class TopazEnhancer
  Result = Struct.new(:io, :filename, :content_type, :metadata, keyword_init: true)

  ALLOWED_FIELDS = %i[
    model
    output_height
    output_width
    output_format
    crop_to_fill
    subject_detection
    face_enhancement
    face_enhancement_creativity
    face_enhancement_strength
    sharpen
    denoise
    fix_compression
    strength
  ].freeze

  def call(source_upload, settings: {})
    ensure_config!
    ensure_image!(source_upload)

    run_at = Time.current
    file_body = source_upload.file.download
    source_sha256 = Digest::SHA256.hexdigest(file_body)

    Rails.logger.info("[Topaz] start enhancement upload_id=#{source_upload.id} model=#{settings[:model] || 'unspecified'} content_type=#{source_upload.content_type} size=#{source_upload.byte_size} sha256=#{source_sha256}")

    response = send_request(source_upload, settings, file_body:)

    Rails.logger.info("[Topaz] response upload_id=#{source_upload.id} status=#{response.code} len=#{response.body&.bytesize} content_type=#{response['Content-Type']}")
    unless response.is_a?(Net::HTTPSuccess)
      raise ImageEnhancers::ConfigurationError, "Topaz API call failed: #{response.code} #{response.message} #{response.body}"
    end

    result_body = response.body.to_s
    result_sha256 = Digest::SHA256.hexdigest(result_body)
    Rails.logger.info("[Topaz] result upload_id=#{source_upload.id} bytes=#{result_body.bytesize} sha256=#{result_sha256}")
    if result_sha256 == source_sha256
      Rails.logger.warn("[Topaz] identical output to input upload_id=#{source_upload.id} sha256=#{result_sha256}")
    end

    content_type = response["Content-Type"] || source_upload.content_type || "image/jpeg"
    filename = derived_filename(source_upload, content_type)

    io = Tempfile.new(["topaz-enhanced", File.extname(filename)], binmode: true)
    io.write(result_body)
    io.rewind

    Result.new(
      io: io,
      filename: filename,
      content_type: content_type,
      metadata: {
        run_at: run_at,
        tool: "topaz",
        settings: settings,
        status: "succeeded",
        provider_job_id: response["X-Process-ID"],
        eta: response["X-ETA"],
        source_sha256: source_sha256,
        result_sha256: result_sha256,
        source_bytes: file_body.bytesize,
        result_bytes: result_body.bytesize,
        note: nil
      }.compact
    )
  end

  private

  def ensure_config!
    url = ENV["TOPAZ_API_URL"]
    key = ENV["TOPAZ_API_KEY"]
    return if url.present? && key.present?

    raise ImageEnhancers::ConfigurationError, "Topaz API credentials are not configured"
  end

  def ensure_image!(upload)
    return if upload.image?

    raise ImageEnhancers::UnsupportedFileError, "Only image uploads can be enhanced"
  end

  def derived_filename(source_upload, content_type = nil)
    base = File.basename(source_upload.original_filename, ".*")
    ext = extension_from_content_type(content_type) || File.extname(source_upload.original_filename)
    suffix = Time.current.strftime("%Y%m%d-%H%M%S")
    "#{base}-topaz-#{suffix}#{ext.presence || '.jpg'}"
  end

  def send_request(source_upload, settings, file_body:)
    uri = URI.join(api_base, "/image/v1/enhance")
    boundary = "----RubyTopaz#{SecureRandom.hex(8)}"

    filtered_settings = settings.to_h.symbolize_keys.slice(*ALLOWED_FIELDS)

    body_parts = []
    filtered_settings.each do |key, value|
      next if value.nil?
      body_parts << build_form_field(boundary, key, value)
    end
    body_parts << build_file_field(boundary, "image", source_upload.original_filename, source_upload.content_type, file_body)
    body_parts << "--#{boundary}--\r\n"

    request = Net::HTTP::Post.new(uri)
    request["X-API-Key"] = ENV["TOPAZ_API_KEY"]
    request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    request["Accept"] = "*/*"
    request.body = body_parts.join

    http = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https")
    http.request(request)
  end

  def build_form_field(boundary, name, value)
    "--#{boundary}\r\nContent-Disposition: form-data; name=\"#{name}\"\r\n\r\n#{value}\r\n"
  end

  def build_file_field(boundary, name, filename, content_type, file_body)
    [
      "--#{boundary}\r\n",
      "Content-Disposition: form-data; name=\"#{name}\"; filename=\"#{filename}\"\r\n",
      "Content-Type: #{content_type || 'application/octet-stream'}\r\n\r\n",
      file_body,
      "\r\n"
    ].join
  end

  def extension_from_content_type(content_type)
    return ".jpg" if content_type&.include?("jpeg") || content_type&.include?("jpg")
    return ".png" if content_type&.include?("png")
    return ".tif" if content_type&.include?("tiff") || content_type&.include?("tif")
    nil
  end

  def api_base
    ENV.fetch("TOPAZ_API_URL")
  end
end
