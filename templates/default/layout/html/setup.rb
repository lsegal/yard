def init
  @breadcrumb = []
  
  @stylesheets = [ "css/style.css",  "css/common.css" ]
  @javascripts = [ "js/jquery.js", "js/app.js" ]
  
  if @onefile
    sections :layout
  elsif @file
    @contents = File.read(@file)
    @file = File.basename(@file)
    @fname = @file.gsub(/\.[^.]+$/, '')
    @breadcrumb_title = "File: " + @fname
    @page_title ||= @breadcrumb_title
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
  data = htmlify(markup_file_contents(@contents), markup_for_file(@contents, @file))
  "<div id='filecontents'>" + data + "</div>"
end
