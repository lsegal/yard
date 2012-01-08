class YARD::Handlers::C::AliasHandler < YARD::Handlers::C::Base
  MATCH = %r{rb_define_alias
             \s*\(\s*([\w\.]+),
             \s*"([^"]+)",
             \s*"([^"]+)"\s*\)}xm
  handles MATCH
  statement_class BodyStatement
  
  process do
    statement.source.scan(MATCH) do |var_name, new_name, old_name|
      var_name = "rb_cObject" if var_name == "rb_mKernel"
      handle_alias(var_name, new_name, old_name)
    end
  end
  
  private
  
  def handle_alias(var_name, new_name, old_name)
    namespace = namespace_for_variable(var_name)
    ensure_loaded!(namespace)
    new_meth, old_meth = new_name.to_sym, old_name.to_sym
    old_obj = namespace.child(:name => old_meth, :scope => :instance)
    new_obj = YARD::CodeObjects::MethodObject.new(namespace, new_meth, :instance) do |o|
      o.visibility = :public
      o.scope = :instance
      o.add_file(statement.file)
      o.source_type = :c
    end

    if old_obj
      new_obj.signature = old_obj.signature
      new_obj.source = old_obj.source
      new_obj.docstring = old_obj.docstring
      new_obj.docstring.object = new_obj
    else
      new_obj.signature = "def #{new_meth}" # this is all we know.
    end

    namespace.aliases[new_obj] = old_meth
  end
end
