def init
  @breadcrumb = []

  if @file
    @contents = File.read_binary(@file)
    @file = File.basename(@file)
    @fname = @file.gsub(/\.[^.]+$/, '')
    @breadcrumb_title = "File: " + @fname
    @page_title ||= @breadcrumb_title
    sections :layout, [:diskfile]
  elsif object
    case object
    when '_index.html'
      @page_title = options[:title]
      sections :layout, [:index]
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
  objects = @objects.reject {|o| o.root? }.sort_by {|o| o.name.to_s }
  objects.each {|o| (@objects_by_letter[o.name.to_s[0,1].upcase] ||= []) << o }
  erb(:index)
end

def diskfile
  "<div id='filecontents'>" +
  case (File.extname(@file)[1..-1] || '').downcase
  when 'htm', 'html'
    @contents
  when 'txt'
    "<pre>#{@contents}</pre>"
  when 'textile', 'txtile'
    htmlify(@contents, :textile)
  when 'markdown', 'md', 'mdown'
    htmlify(@contents, :markdown)
  else
    htmlify(@contents, diskfile_shebang_or_default)
  end +
  "</div>"
end

def diskfile_shebang_or_default
  if @contents =~ /\A#!(\S+)\s*$/ # Shebang support
    @contents = $'
    $1.to_sym
  else
    options[:markup]
  end
end