module YARD
  module Server
    # Registers a static path to be used in static asset lookup.
    # @param [String] path the pathname to register
    # @return [void]
    def self.register_static_path(path)
      Commands::StaticFileCommand::STATIC_PATHS.push(path)
    end
  end
end