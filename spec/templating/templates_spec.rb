require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::Templates do
  describe '.render' do
    def loads_template(*args)
      Template.should_receive(:template).with(*args).and_return(@template)
    end
  
    before do 
      @template = mock(:template)
      @template.stub!(:include)
      @object = CodeObjects::MethodObject.new(:root, :method)
    end
  
    it "should accept method call with no parameters" do
      loads_template(:default, :text, :method)
      @template.should_receive(:run).with :type => :method,
                                          :template => :default,
                                          :format => :text,
                                          :object => @object,
                                          :serializer => nil
      @object.format
    end
  
    it "should allow template key to be changed" do
      loads_template(:javadoc, :text, :method)
      @template.should_receive(:run).with :type => :method,
                                          :template => :javadoc,
                                          :format => :text,
                                          :object => @object,
                                          :serializer => nil
      @object.format(:template => :javadoc)
    end

    it "should allow type key to be changed" do
      loads_template(:default, :text, :fulldoc)
      @template.should_receive(:run).with :type => :fulldoc,
                                          :template => :default,
                                          :format => :text,
                                          :object => @object,
                                          :serializer => nil
      @object.format(:type => :fulldoc)
    end
  
    it "should allow format key to be changed" do
      loads_template(:default, :html, :method)
      @template.should_receive(:run).with :type => :method,
                                          :template => :default,
                                          :format => :html,
                                          :object => @object,
                                          :serializer => nil
      @object.format(:format => :html)
    end
  end
end
