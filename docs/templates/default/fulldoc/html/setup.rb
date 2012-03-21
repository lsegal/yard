def generate_tag_list
  @list_title = "Tag List"
  @list_type = "tag"
  contents = T('yard_tags').run(options)
  page = T('layout').run(options.merge(:contents => contents, :breadcrumb_title => "YARD Tags List"))
  asset('tag_list.html', erb(:full_list))
  asset('tag_page.html', page)
end

