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
    when 'glossary.html'
      sections :header, [:glossary]
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
      sections :header, [T("../#{type}")]
    end
  else
    sections :header, [:contents]
  end
end

def contents
  @contents
end

def glossary
  @objects_by_letter = {}
  @page_title = options[:title] || "Project Documentation (yard #{YARD::VERSION})"
  objects = @objects.reject {|o| o == Registry.root }.sort_by {|o| o.name.to_s }
  objects.each {|o| (@objects_by_letter[o.name[0].upcase] ||= []) << o }
  erb(:glossary)
end

def diskfile
  "<div id='filecontents'>" +
  case (File.extname(@file)[1..-1] || '').downcase
  when 'textile', 'txtile'
    htmlify(@contents, :textile)
  when 'markdown', 'md', 'mdown'
    htmlify(@contents, :markdown)
  when 'rdoc'
    htmlify(@contents, :rdoc)
  else
    "<pre>#{@contents}</pre>"
  end +
  "</div>"
end