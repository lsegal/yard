require 'fileutils'

module YARD
  class RegistryStore
    attr_reader :proxy_types, :file, :checksums
    
    def initialize
      @file = nil
      @checksums = {}
      @store = { :root => CodeObjects::RootObject.new(nil, :root) }
      @proxy_types = {}
      @loaded_objects = 0
      @available_objects = 0
    end
    
    def get(key)
      key = :root if key == ''
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
      
    def keys; load_all; @store.keys end
    def values(reload = true) load_all if reload; @store.values end
    
    def root; @store[:root] end
      
    def load(file = nil)
      @file = file
      @store = {}
      @proxy_types = {}
      @serializer = Serializers::YardocSerializer.new(@file)
      load_yardoc
    end
    
    def save(merge = true, file = nil)
      if file && file != @file
        @file = file
        @serializer = Serializers::YardocSerializer.new(@file)
      end
      destroy unless merge
      values(false).each do |object|
        @serializer.serialize(object)
      end
      write_proxy_types
      write_checksums
      true
    end
    
    # Deletes the .yardoc database on disk
    # 
    # @param [Boolean] safe if safe is set to true, the file/directory
    #   will only be removed if it ends with .yardoc. This helps with
    #   cases where the directory might have been named incorrectly.
    # @return [Boolean] true if the .yardoc database was deleted, false
    #   otherwise.
    def destroy(safe = true)
      if (safe && file =~ /\.yardoc$/) || !safe
        if File.file?(@file) 
          # Handle silent upgrade of old .yardoc format
          File.unlink(@file) 
        elsif File.directory?(@file)
          FileUtils.rm_rf(@file)
        end
        true
      else
        false
      end
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
    
    def checksums_path
      @serializer.checksums_path
    end
    
    def load_yardoc
      return false unless @file
      if File.directory?(@file) # new format
        Registry.objects.replace({})
        @loaded_objects = 0
        @available_objects = all_disk_objects.size
        load_proxy_types
        load_checksums
        load_root
        true
      elsif File.file?(@file) # old format
        load_yardoc_old
        true
      else
        false
      end
    end
    
    def load_yardoc_old
      @store, @proxy_types = *Marshal.load(File.read(@file))
    end
    
    private
    
    def load_proxy_types
      return unless File.file?(proxy_types_path)
      @proxy_types = Marshal.load(File.read(proxy_types_path))
    end
    
    def load_checksums
      return unless File.file?(checksums_path)
      lines = File.readlines(checksums_path).map do |line|
        line.strip.split(/\s+/)
      end
      @checksums = Hash[lines]
    end
    
    def load_root
      if root = @serializer.deserialize('root')
        @store[:root] = root
      end
    end
    
    def load_all
      return unless @file
      return if @loaded_objects >= @available_objects
      log.debug "Loading entire database: #{@file} ..."
      objects = []
      
      all_disk_objects.sort_by {|x| x.size }.each do |path|
        if obj = @serializer.deserialize(path, true)
          objects << obj
        end
      end
      objects.each do |obj|
        put(obj.path, obj)
      end
      @loaded_objects += objects.size
      log.debug "Loaded database (file='#{@file}' count=#{objects.size} total=#{@available_objects})"
    end

    def all_disk_objects
      Dir.glob(File.join(objects_path, '**/*')).select {|f| File.file?(f) }
    end
    
    def write_proxy_types
      File.open(proxy_types_path, 'wb') {|f| f.write(Marshal.dump(@proxy_types)) }
    end
    
    def write_checksums
      File.open(checksums_path, 'w') do |f|
        @checksums.each {|k, v| f.puts("#{k} #{v}") }
      end
    end
  end
end