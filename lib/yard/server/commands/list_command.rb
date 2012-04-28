module YARD
  module Server
    module Commands
      # Returns a list of objects of a specific type
      class ListCommand < LibraryCommand
        include Templates::Helpers::BaseHelper

        def run
          Registry.load_all
          options.update(:objects => run_verifier(Registry.all(:class, :module)))
          list_type = request.path.split('/').last
          meth = "generate_#{list_type}_list"
          tpl = fulldoc_template
          tpl.respond_to?(meth) ? cache(tpl.send(meth)) : not_found
        end

        private

        # Hack to load a custom fulldoc template object that does
        # not do any rendering/generation. We need this to access the
        # generate_*_list methods.
        def fulldoc_template
          tplopts = [options.template, :fulldoc, options.format]
          tplclass = Templates::Engine.template(*tplopts)
          obj = Object.new.extend(tplclass)
          class << obj; def init; end end
          obj.class = tplclass
          obj.send(:initialize, options)
          class << obj; def asset(file, contents) contents end end
          obj
        end
      end
    end
  end
end
