include YARD
include Templates

module TagTemplateHelper
  def all_tags
    Registry.all(:method).map {|m| m.tag('yard.tag') }.compact
  end

  def all_directives
    Registry.all(:method).map {|m| m.tag('yard.directive') }.compact
  end

  def collect_tags
    (all_tags + all_directives).sort_by {|t| t.name }
  end

  def tag_link(tag)
    prefix = tag.tag_name == 'yard.directive' ? '@!' : '@'
    link_url('tag_page.html#' + tag.name, h(prefix + tag.name))
  end
end

Template.extra_includes << TagTemplateHelper
Engine.register_template_path(File.dirname(__FILE__) + '/templates')
