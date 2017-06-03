# frozen_string_literal: true
class YARD::Handlers::C::AliasHandler < YARD::Handlers::C::Base
  MATCH1 = /rb_define_alias
             \s*\(\s*([\w\.]+),
             \s*"([^"]+)",
             \s*"([^"]+)"\s*\)/xm
  MATCH2 = /rb_define_alias
             \s*\(\s*rb_singleton_class\s*\(\s*([\w\.]+)\s*\)\s*,
             \s*"([^"]+)",
             \s*"([^"]+)"\s*\)/xm
  handles MATCH1
  handles MATCH2
  statement_class BodyStatement

  process do
    statement.source.scan(MATCH1) do |var_name, new_name, old_name|
      var_name = "rb_cObject" if var_name == "rb_mKernel"
      handle_alias(var_name, new_name, old_name)
    end

    statement.source.scan(MATCH2) do |var_name, new_name, old_name|
      var_name = "rb_cObject" if var_name == "rb_mKernel"
      handle_alias(var_name, new_name, old_name, :class)
    end
  end
end
