require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects, "CONSTANTMATCH" do
  it "should match a constant" do
    expect("Constant"[CodeObjects::CONSTANTMATCH]).to eq "Constant"
    expect("identifier"[CodeObjects::CONSTANTMATCH]).to be_nil
    expect("File.new"[CodeObjects::CONSTANTMATCH]).to eq "File"
  end
end

describe YARD::CodeObjects, "NAMESPACEMATCH" do
  it "should match a namespace (multiple constants with ::)" do
    expect("Constant"[CodeObjects::NAMESPACEMATCH]).to eq "Constant"
    expect("A::B::C.new"[CodeObjects::NAMESPACEMATCH]).to eq "A::B::C"
  end
end

describe YARD::CodeObjects, "METHODNAMEMATCH" do
  it "should match a method name" do
    expect("method"[CodeObjects::METHODNAMEMATCH]).to eq "method"
    expect("[]()"[CodeObjects::METHODNAMEMATCH]).to eq "[]"
    expect("-@"[CodeObjects::METHODNAMEMATCH]).to eq "-@"
    expect("method?"[CodeObjects::METHODNAMEMATCH]).to eq "method?"
    expect("method!!"[CodeObjects::METHODNAMEMATCH]).to eq "method!"
  end
end

describe YARD::CodeObjects, "METHODMATCH" do
  it "should match a full class method path" do
    expect("method"[CodeObjects::METHODMATCH]).to eq "method"
    expect("A::B::C.method?"[CodeObjects::METHODMATCH]).to eq "A::B::C.method?"
    expect("A::B::C :: method"[CodeObjects::METHODMATCH]).to eq "A::B::C :: method"
    expect("SomeClass . method"[CodeObjects::METHODMATCH]).to eq "SomeClass . method"
  end

  it "should match self.method" do
    expect("self :: method!"[CodeObjects::METHODMATCH]).to eq "self :: method!"
    expect("self.is_a?"[CodeObjects::METHODMATCH]).to eq "self.is_a?"
  end
end

describe YARD::CodeObjects, "BUILTIN_EXCEPTIONS" do
  it "should include all base exceptions" do
    YARD::CodeObjects::BUILTIN_EXCEPTIONS.each do |name|
      expect(eval(name)).to be <= Exception
    end
  end
end

describe YARD::CodeObjects, "BUILTIN_CLASSES" do
  it "should include all base classes" do
    YARD::CodeObjects::BUILTIN_CLASSES.each do |name|
      next if name == "MatchingData" && !defined?(::MatchingData)
      next if name == "Continuation"
      expect(eval(name)).to be_instance_of(Class)
    end
  end

  it "should include all exceptions" do
    YARD::CodeObjects::BUILTIN_EXCEPTIONS.each do |name|
      expect(YARD::CodeObjects::BUILTIN_CLASSES).to include(name)
    end
  end
end

describe YARD::CodeObjects, "BUILTIN_ALL" do
  it "should include classes modules and exceptions" do
    a = YARD::CodeObjects::BUILTIN_ALL
    b = YARD::CodeObjects::BUILTIN_CLASSES
    c = YARD::CodeObjects::BUILTIN_MODULES
    expect(a).to eq b+c
  end
end

describe YARD::CodeObjects, "BUILTIN_MODULES" do
  it "should include all base modules" do
    YARD::CodeObjects::BUILTIN_MODULES.each do |name|
      next if YARD.ruby19? && ["Precision"].include?(name)
      expect(eval(name)).to be_instance_of(Module)
    end
  end
end