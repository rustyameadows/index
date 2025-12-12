module ImageEnhancers
  class ConfigurationError < StandardError; end
  class UnsupportedFileError < StandardError; end

  REGISTRY = {
    topaz: -> { TopazEnhancer.new }
  }.freeze

  def self.fetch(provider)
    builder = REGISTRY[provider.to_sym]
    raise ConfigurationError, "Provider not available" unless builder

    builder.call
  end
end
