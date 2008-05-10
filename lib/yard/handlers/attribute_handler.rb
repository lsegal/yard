class YARD::Handlers::AttributeHandler < YARD::Handlers::Base
  handles /\Aattr(?:_(?:reader|writer|accessor))?(?:\s|\()/
end