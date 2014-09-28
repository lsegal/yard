def init
  options.delete(:objects)
  options.files.each {|file| serialize_file(file) }
  serialize_file(options.readme)
end

def serialize_file(file)
  index = options.files.index(file)
  outfile = file.filename.downcase
  options.file = file
  options.object = Registry.root

  Templates::Engine.with_serializer(outfile, options.serializer) do
    T('layout').run(options)
  end
  options.delete(:file)
end
