def init
  super
  sections.place(:tag_list).after_any(:files)
end

def javascripts
  super + %w(js/tag_list.js)
end

def tag_list
  @items = Registry.all(:method).select {|m| m.has_tag?('yard.tag') }
  erb(:tag_list)
end

def menu_lists
  super + [{:type => 'tag', :title => 'Tags', :search_title => 'Tag List'}]
end
