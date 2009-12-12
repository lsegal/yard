module YARD
  class StubProxy
    instance_methods.each {|m| undef_method(m) unless m.to_s =~ /^__|^object_id$/ }
    
    def initialize(path, transient = false) 
      @path = path
      @transient = transient
    end
    
    def method_missing(meth, *args, &block)
      return Registry.at(@path).send(meth, *args, &block) if @transient
      @object ||= Registry.at(@path)
      @object.send(meth, *args, &block)
    end
    
    def _dump(depth) @path end
    def _load(str) StubProxy.new(str) end
  end

  module Serializers
    class YardocSerializer < FileSystemSerializer
      def initialize(yfile)
        super(:basepath => yfile, :extension => 'dat')
      end
      
      def objects_path; File.join(basepath, 'objects') end
      def proxy_types_path; File.join(basepath, 'proxy_types') end
      
      def serialized_path(object)
        path = case object
        when String, Symbol
          object = object.to_s
          if object =~ /#/
            object += '_i'
          elsif object =~ /\./
            object += '_c'
          end
          object.split(/::|\.|#/).map do |p|
            p.gsub(/[^\w\.-]/) do |x|
              encoded = '_'

              x.each_byte { |b| encoded << ("%X" % b) }
              encoded
            end
          end.join('/') + '.' + extension
        when YARD::CodeObjects::RootObject
          'root.dat'
        else
          super(object)
        end
        File.join('objects', path)
      end
      
      def serialize(object)
        super(object, dump(object))
      end
      
      def deserialize(path, is_path = false)
        path = File.join(basepath, serialized_path(path)) unless is_path
        if File.file?(path)
          log.debug "Deserializing #{path}..."
          Marshal.load(File.read(path))
        else
          log.debug "Could not find #{path}"
          nil
        end
      end
      
      private
      
      def dump(object)
        Marshal.dump(internal_dump(object, true))
      end
      
      def internal_dump(object, first_object = false)
        if !first_object && object.is_a?(CodeObjects::Base)
          return StubProxy.new(object.path, true)
        end
        
        object_track = {}
        
        if object.is_a?(Hash) || object.is_a?(Array) || 
            object.is_a?(CodeObjects::Base) ||
            object.instance_variables.size > 0
          object = object.dup
        end
        
        object.instance_variables.each do |ivar|
          ivar_obj = object.instance_variable_get(ivar)
          if ivar_obj.is_a?(CodeObjects::Base)
            object_track[ivar_obj.path] ||= internal_dump(ivar_obj)
            ivar_obj_dump = object_track[ivar_obj.path]
          else
            ivar_obj_dump = internal_dump(ivar_obj)
          end
          object.instance_variable_set(ivar, ivar_obj_dump)
        end
        
        case object
        when Hash
          list = object.map do |k, v|
            [k, v].map do |item| 
              if item.is_a?(CodeObjects::Base)
                object_track[item.path] ||= internal_dump(item)
              else
                internal_dump(item)
              end
            end
          end
          object.replace(Hash[list])
        when Array
          list = object.map do |item| 
            if item.is_a?(CodeObjects::Base)
              object_track[item.path] ||= internal_dump(item)
            else
              internal_dump(item)
            end
          end
          object.replace(list)
        end
        
        object
      end
    end
  end
end