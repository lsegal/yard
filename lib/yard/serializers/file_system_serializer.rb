require 'fileutils'

module YARD
  module Serializers
    class FileSystemSerializer < Base
      attr_reader :basepath, :extension
      
      def initialize(opts = {})
        super
        @basepath = (options[:basepath] || 'doc').to_s
        @extension = (options[:extension] || 'html').to_s
      end
      
      def serialize(object, data)
        path = serialized_path(object)
        FileUtils.mkdir_p File.join(*path.split('/')[0..-2])
        YARD.logger.debug "Serializing to #{path}"
        File.open(path, "w") {|f| f.write data }
      end
      
      def serialized_path(object)
        fspath = [object.name.to_s + ".#{extension}"]
        if object.namespace && object.namespace.path != ""
          fspath.unshift *object.namespace.path.split(CodeObjects::NSEP)
        end
        
        # Don't change the filenames, it just makes it more complicated
        # to figure out the original name.
        #fspath.map! do |p| 
        #  p.gsub(/([a-z])([A-Z])/, '\1_\2').downcase 
        #end
        
        File.join(basepath, *fspath)
      end
    end
  end
end