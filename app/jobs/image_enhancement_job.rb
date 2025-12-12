class ImageEnhancementJob < ApplicationJob
  queue_as :default

  def perform(source_upload_id, provider:, settings: {})
    source = Upload.find(source_upload_id)
    enhancer = ImageEnhancers.fetch(provider)

    result = enhancer.call(source, settings: settings.deep_symbolize_keys)

    derived = source.derived_uploads.build(
      project: source.project,
      user: source.user,
      original_filename: result.filename || derived_filename(source),
      content_type: result.content_type || source.content_type,
      uploaded_at: result.metadata[:run_at] || Time.current,
      processing_metadata: base_metadata(provider, settings, result.metadata, "succeeded")
    )

    derived.file.attach(io: result.io, filename: derived.original_filename, content_type: derived.content_type)
    derived.byte_size = derived.file.blob.byte_size
    derived.save!
  rescue ImageEnhancers::ConfigurationError => e
    record_failure(source, provider, settings, e.message)
  rescue StandardError => e
    record_failure(source, provider, settings, e.message)
    raise
  end

  private

  def base_metadata(provider, settings, result_metadata, status)
    {
      "tool" => provider.to_s,
      "settings" => settings,
      "status" => status,
      "run_at" => Time.current,
      "provider_job_id" => result_metadata[:provider_job_id],
      "eta" => result_metadata[:eta],
      "source_sha256" => result_metadata[:source_sha256],
      "result_sha256" => result_metadata[:result_sha256],
      "source_bytes" => result_metadata[:source_bytes],
      "result_bytes" => result_metadata[:result_bytes],
      "raw_response" => result_metadata[:raw_response],
      "note" => result_metadata[:note]
    }.compact
  end

  def derived_filename(source)
    base = File.basename(source.original_filename, ".*")
    ext = File.extname(source.original_filename)
    "#{base}-enhanced#{ext.presence || '.png'}"
  end

  def record_failure(source, provider, settings, error_message)
    source.update_column(
      :processing_metadata,
      {
        "tool" => provider.to_s,
        "settings" => settings,
        "status" => "failed",
        "run_at" => Time.current,
        "error" => error_message
      }
    )
  end
end
