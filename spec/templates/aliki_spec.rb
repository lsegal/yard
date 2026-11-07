# frozen_string_literal: true

require File.expand_path('spec_helper', __dir__)
require 'json'

class AlikiStringSerializer < YARD::Serializers::Base
  attr_reader :files, :output

  def initialize
    super
    @files = []
    @output = {}
    @filesystem = YARD::Serializers::FileSystemSerializer.new
  end

  def serialize(object, data)
    files << object
    output[serialized_path(object)] = data
  end

  def serialized_path(object)
    @filesystem.serialized_path(object)
  end
end

RSpec.describe "Aliki HTML template" do
  before do
    Registry.clear
    YARD.parse_string <<-RUBY
      # A test class.
      class A
        # Returns foo.
        # @return [String]
        def foo; 'foo' end
      end
    RUBY
  end

  after do
    Registry.clear
  end

  it "generates Aliki assets, pages, object output, and search data" do
    serializer = AlikiStringSerializer.new
    readme = CodeObjects::ExtraFileObject.new('README', '# Readme')

    Templates::Engine.generate Registry.all(:class),
                               :serializer => serializer,
                               :template => :aliki,
                               :format => :html,
                               :readme => readme,
                               :files => [readme]

    expect(serializer.files).to include(
      'css/rdoc.css', 'css/yard.css', 'js/aliki.js', 'js/search_data.js'
    )
    expect(serializer.output['index.html']).to include('class="file has-toc"')
    expect(serializer.output['A.html']).to include('Classes and Modules')
    expect(serializer.output['A.html']).to include('<span class="nav-section-title">Pages</span>')
    expect(serializer.output['A.html']).to include('method-detail anchor-link')

    search_data = serializer.output['js/search_data.js'].
      sub(/\Avar search_data = /, '').
      sub(/;\z/, '')
    index = JSON.parse(search_data).fetch('index')
    expect(index).to include(hash_including('name' => 'A', 'type' => 'class', 'path' => 'A.html'))
    expect(index).to include(
      hash_including(
        'name' => 'foo',
        'type' => 'instance_method',
        'path' => 'A.html#foo-instance_method'
      )
    )
  end
end
