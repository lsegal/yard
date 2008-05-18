require 'fileutils'

module YARD
  module Serializers
    class FileSystemSerializer < Base
      attr_reader :basepath, :extension
      
      def initialize(basepath, extension)
        @basepath = options[:basepath] || '.' 
        @extension = options[:extension] || 'html'
      end
      
      def serialize(object, data)
        path = fs_path(object)
        FileUtils.mkdir_p path.gsub(/#{object.name}\.#{extension}$/, '')
        YARD.logger.debug "Serializing to #{path}"
        File.new(path, "w") {|f| f.write data }
      end
      
      protected
      
      def fs_path(object)
        fspath = [
          object.namespace.path.split(CodeObjects::NSEP), 
          object.name.to_s + ".#{extension}"
        ].flatten.map do |p| 
          p.gsub(/([a-z])([A-Z])/) {|a| a[0] + "_" + a[1].downcase } 
        end
        
        File.join(basepath, *fspath)
      end
    end
  end
end