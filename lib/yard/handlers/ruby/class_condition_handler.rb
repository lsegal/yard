class YARD::Handlers::Ruby::ClassConditionHandler < YARD::Handlers::Ruby::Base
  namespace_only
  handles meta_type(:condition)
  
  def process
    # TODO we have the opportunity to be smart about literal conditionals
    # here. Currently we parse the inner block(s) no matter what, but we
    # could theoretically avoid parsing things like +if 0+ or even constants
    # that have been previously defined (it would be a fair assumption to
    # treat constants as having "true" static constant value).
    parse_block(statement.then_block)
    parse_block(statement.else_block) if statement.else_block
  end
end