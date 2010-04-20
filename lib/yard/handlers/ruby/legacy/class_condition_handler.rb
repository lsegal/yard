class YARD::Handlers::Ruby::Legacy::ClassConditionHandler < YARD::Handlers::Ruby::Legacy::Base
  namespace_only
  handles TkIF, TkELSIF, TkELSE, TkUNLESS
  
  process do
    parse_block
  end
end