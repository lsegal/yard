def init
  @breadcrumb = []

  if @file
    @contents = IO.read(@file)
    @file = File.basename(@file)
    @fname = @file.gsub(/\..+$/, '')
    @breadcrumb_title = "File: " + @fname
    sections :header, [:diskfile]
  elsif object
    case object
    when '_index.html'
      sections :header, [:index]
    when CodeObjects::Base
      if object != Registry.root
        cur = object.namespace
        while cur != Registry.root
          @breadcrumb.unshift(cur)
          cur = cur.namespace
        end
      end
    
      @page_title = format_object_title(object)
      type = object == Registry.root ? :module : object.type
      sections :header, [T(type)]
    end
  else
    sections :header, [:contents]
  end
end

def contents
  @contents
end

def index
  @objects_by_letter = {}
  @page_title = options[:title] || ""
  @page_title = "Project Documentation (yard #{YARD::VERSION})" if @page_title.empty?
  objects = @objects.reject {|o| o == Registry.root }.sort_by {|o| o.name.to_s }
  objects.each {|o| (@objects_by_letter[o.name.to_s[0,1].upcase] ||= []) << o }
  erb(:index)
end

def diskfile
  "<div id='filecontents'>" +
  case (File.extname(@file)[1..-1] || '').downcase
  when 'txt'
    "<pre>#{@contents}</pre>"
  when 'textile', 'txtile'
    htmlify(@contents, :textile)
  when 'markdown', 'md', 'mdown'
    htmlify(@contents, :markdown)
  else
    htmlify(@contents, :rdoc)
  end +
  "</div>"
end