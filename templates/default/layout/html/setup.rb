def init
  @breadcrumb = []

  if @onefile
    sections :layout
  elsif @file
    if @file.attributes[:namespace]
      @object = options[:object] = Registry.at(@file.attributes[:namespace]) || Registry.root 
    end
    @breadcrumb_title = "File: " + @file.title
    @page_title = @breadcrumb_title
    sections :layout, [:diskfile]
  elsif object
    case object
    when '_index.html'
      @page_title = options[:title]
      sections :layout, [:index, [:listing, [:files, :objects]]]
    when CodeObjects::Base
      unless object.root?
        cur = object.namespace
        while !cur.root?
          @breadcrumb.unshift(cur)
          cur = cur.namespace
        end
      end
    
      @page_title = format_object_title(object)
      type = object.root? ? :module : object.type
      sections :layout, [T(type)]
    end
  else
    sections :layout, [:contents]
  end
end

def contents
  @contents
end

def index
  @objects_by_letter = {}
  objects = Registry.all(:class, :module).sort_by {|o| o.name.to_s }
  objects = run_verifier(objects)
  objects.each {|o| (@objects_by_letter[o.name.to_s[0,1].upcase] ||= []) << o }
  erb(:index)
end

def diskfile
  @file.attributes[:markup] ||= markup_for_file('', @file.filename)
  data = htmlify(@file.contents, @file.attributes[:markup])
  "<div id='filecontents'>" + data + "</div>"
end
