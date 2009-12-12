require 'fileutils'

module YARD
  class RegistryStore
    attr_accessor :proxy_types, :file
    
    def initialize
      @file = nil
      @store = { :root => CodeObjects::RootObject.new(nil, :root) }
      @proxy_types = {}
      @loaded_objects = 0
      @available_objects = 0
    end
    
    def get(key)
      return root if key == '' || key == :root
      key = key.to_sym
      return @store[key] if @store[key]
      return nil if @loaded_objects >= @available_objects

      # check disk
      if obj = @serializer.deserialize(key)
        @loaded_objects += 1
        put(key, obj)
      end
    end
    
    def put(key, value)
      if key == ''
        @store[:root] = value
      else
        @store[key.to_sym] = value 
      end
    end
    
    def delete(key) @store.delete(key.to_sym) end
    def [](key) get(key) end
    def []=(key, value) put(key, value) end
      
    def keys; @store.keys end
    def values; @store.values end
    
    def root; @store[:root] end
      
    def load(file = nil)
      @file = file
      @store = {}
      @proxy_types = {}
      @serializer = Serializers::YardocSerializer.new(@file)
      load_yardoc
    end
    
    def save(file = nil)
      if file && file != @file
        @file = file
        @serializer = Serializers::YardocSerializer.new(@file)
      end
      
      if file =~ /\.yardoc$/
        if File.file?(@file) 
          # Handle silent upgrade of old .yardoc format
          File.unlink(@file) 
        elsif File.directory?(@file)
          FileUtils.rm_rf(@file)
        end
      end
      
      values.each do |object|
        @serializer.serialize(object)
      end
      File.open(proxy_types_path, 'wb') {|f| f.write(Marshal.dump(@proxy_types)) }
    end
    
    protected
    
    def path_for(key)
      @serializer.serialized_path(key)
    end
    
    def objects_path
      @serializer.objects_path
    end
    
    def proxy_types_path
      @serializer.proxy_types_path
    end
    
    def load_yardoc
      return unless @file
      if File.directory?(@file) # new format
        Registry.objects.replace({})
        path = File.join(objects_path, '**/*')
        @loaded_objects = 0
        @available_objects = Dir.glob(path).select {|f| File.file?(f) }.size
        if File.file?(proxy_types_path)
          @proxy_types = Marshal.load(File.read(proxy_types_path))
        end
        true
      elsif File.file?(@file) # old format
        load_yardoc_old
      end
      false
    end
    
    def load_yardoc_old
      @store, @proxy_types = *Marshal.load(File.read(@file))
    end
  end
end