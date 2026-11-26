# frozen_string_literal: true
require File.dirname(__FILE__) + '/spec_helper'

RSpec.describe YARD::Handlers::RBS::MixinHandler do
  it "registers include as instance mixin" do
    parse_rbs <<-RBS
module Helpers
end
class Foo
  include Helpers
end
    RBS
    expect(Registry.at('Foo').mixins(:instance).map(&:path)).to include('Helpers')
  end

  it "registers extend as class mixin" do
    parse_rbs <<-RBS
module ClassMethods
end
class Foo
  extend ClassMethods
end
    RBS
    expect(Registry.at('Foo').mixins(:class).map(&:path)).to include('ClassMethods')
  end

  it "registers prepend as instance mixin" do
    parse_rbs <<-RBS
module Before
end
class Foo
  prepend Before
end
    RBS
    expect(Registry.at('Foo').mixins(:instance).map(&:path)).to include('Before')
  end

  it "drops type arguments from the mixin name" do
    parse_rbs <<-RBS
module Countable[T]
  def count: () -> Integer
end
module Keyed[K, V]
  def keys: () -> Array[K]
end
interface _Items[T]
  def each: () { (T) -> void } -> void
end
class Bag
  include Countable[Integer]
  include Keyed[Symbol, Integer]
  include _Items[Integer]
end
    RBS
    bag = Registry.at('Bag')
    expect(bag.mixins(:instance).map(&:path)).to eq(['Countable', 'Keyed', '_Items'])
    expect(bag.meths.map(&:path)).to include('Countable#count', 'Keyed#keys', '_Items#each')
  end

  it "follows a constant alias to the module it names" do
    Registry.clear
    YARD.parse_string <<-RUBY
module Foo
  module Real
    def go; end
  end
  Filtering = Real
end
    RUBY
    YARD.parse_string(<<-RBS, :rbs)
module Foo
  class Host
    include Foo::Filtering
  end
end
    RBS
    expect(Registry.at('Foo::Host').mixins(:instance).map(&:path)).to eq(['Foo::Real'])
  end
end
