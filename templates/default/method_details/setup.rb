inherits '../method_summary'

def init
  super
  sections[1].replace [:details, ['../method']]
end