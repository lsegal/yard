module YARD
  module Generators
    class UMLGenerator < Base
      include Helpers::UMLHelper
      
      before_generate :init
      before_section :dependencies, :show_dependencies?
      
      def sections_for(object)
        [
          :header, 
          [ 
            :unknown, [:unresolved, [:unknown_child]],
            :subgraph, [:info],
            :superclasses,
            :dependencies
          ]
        ]
      end
      
      def header(object, &block)
        tidy render(object, :header, &block)
      end
      
      def subgraph(object, &block)
        name = namespaces(object).empty? ? :child : :subgraph
        render(object, name, &block)
      end
      
      def unresolved(object, &block)
        @objects.select {|o| o.is_a?(CodeObjects::Proxy) }.map {|o| yield(o) }.join("\n")
      end
      
      protected
      
      def show_full_info?;    options.has_key? :full end
      def show_dependencies?; options.has_key? :dependencies end
      
      def init(object)
        @objects = {}
        process_objects(object)
        @objects = @objects.values
      end
      
      def namespaces(object)
        object.children.select {|o| o.is_a?(CodeObjects::NamespaceObject) }
      end
      
      def unresolved_objects
        @direction_paths.values.flatten.select {|o| o.is_a?(CodeObjects::Proxy) }.uniq
      end
      
      def format_path(object)
        object.path.gsub('::', '_')
      end
      
      def h(text)
        text.to_s.gsub(/(\W)/, '\\\\\1')
      end
      
      def process_objects(object)
        @objects[object.path] = object
        @objects[object.superclass.path] = object.superclass if object.is_a?(CodeObjects::ClassObject) && object.superclass
        object.mixins.each {|o| @objects[o.path] = o }

        namespaces(object).each {|o| process_objects(o) }
      end
      
      def method_list(object, attributes = false)
        vissort = lambda {|vis| vis == :public ? 'a' : (vis == :protected ? 'b' : 'c') }
        
        meths = object.meths(:inherited => false, :included => false, :visibility => options[:visibility])
        meths = remove_overriden_meths(object, meths)
        meths = meths.select {|o| attributes ? o.is_attribute? : !o.is_attribute? }
        meths = meths.reject {|o| o.is_alias? }
        meths = meths.sort_by {|o| "#{o.scope}#{vissort.call(o.visibility)}#{o.name}" }
      end
      
      private
      
      def remove_overriden_meths(object, meth_list)
        object.inheritance_tree(true)[1..-1].each do |sclass|
          next if CodeObjects::Proxy === sclass
          meth_list.reject! {|o| sclass.child(:scope => o.scope, :name => o.name) }
        end
        meth_list
      end
      
      def tidy(data)
        indent = 0
        data.split(/\n/).map do |line|
          line.gsub!(/^\s*/, '')
          next if line.empty?
          indent -= 1 if line =~ /^\s*\}\s*$/
          line = (' ' * (indent * 2)) + line
          indent += 1 if line =~ /\{\s*$/
          line
        end.compact.join("\n") + "\n"
      end
    end
  end
end
