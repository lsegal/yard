require 'fileutils'

module YARD
  module Serializers
    class FileSystemSerializer < Base
      attr_reader :basepath, :extension
      
      def initialize(opts = {})
        super
        @basepath = (options[:basepath] || 'doc').to_s
        @extension = (options.has_key?(:extension) ? options[:extension] : 'html').to_s
      end
      
      def serialize(object, data)
        path = File.join(basepath, *serialized_path(object))
        FileUtils.mkdir_p File.dirname(path)
        log.debug "Serializing to #{path}"
        File.open(path, "w") {|f| f.write data }
      end
      
      def serialized_path(object)
        return object if object.is_a?(String)

        objname = object.name.to_s
        objname += '_' + object.scope.to_s[0,1] if object.is_a?(CodeObjects::MethodObject)
        fspath = [objname + (extension.empty? ? '' : ".#{extension}")]
        if object.namespace && object.namespace.path != ""
          fspath.unshift *object.namespace.path.split(CodeObjects::NSEP)
        end
        
        # Don't change the filenames, it just makes it more complicated
        # to figure out the original name.
        #fspath.map! do |p| 
        #  p.gsub(/([a-z])([A-Z])/, '\1_\2').downcase 
        #end
        
        # Remove special chars from filenames.
        # Windows disallows \ / : * ? " < > | but we will just remove any
        # non alphanumeric (plus period, underscore and dash).
        fspath.map! do |p|
          p.gsub(/[^\w\.-]/) do |x|
            encoded = '_'

            x.each_byte { |b| encoded << ("%X" % b) }
            encoded
          end
        end
        
        File.join(fspath)
      end
    end
  end
end
