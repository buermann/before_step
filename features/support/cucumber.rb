require 'cucumber'
#Cucumber::Ast::StepInvocation.class_eval do
# class_eval loses the Pending exception class scope that would otherwise be there,
# and would require the fully qualified class name, which I forget at the moment,
# hence the duck typing with false laziness:
module Cucumber
  module Ast
    class StepInvocation #:nodoc:
      include Gherkin::Rubify
      def invoke(step_mother, options)
        find_step_match!(step_mother)
        unless @skip_invoke || options[:dry_run] || @exception || @step_collection.exception
          begin
            step_mother.before_step
            @step_match.invoke(@multiline_arg)
            step_mother.after_step
            status!(:passed)
          rescue Pending => e
            failed(options, e, false)
            status!(:pending)
          rescue Undefined => e
            failed(options, e, false)
            status!(:undefined)
          rescue Cucumber::Ast::Table::Different => e
            @different_table = e.table
            failed(options, e, false)
            status!(:failed)
          rescue Exception => e
            failed(options, e, false)
            status!(:failed)
          end
        end
      end
    end
  end
end

Cucumber::LanguageSupport::LanguageMethods.class_eval do
  def execute_before_step(step)
    hooks_for(:before_step, step).each do |hook|
      invoke(hook, 'BeforeStep', step, false)
    end
  end
end

module Cucumber
  module RbSupport
    module RbDsl
      def BeforeStep(*tag_expressions, &proc)
        RbDsl.register_rb_hook('before_step', tag_expressions, proc)
      end
    end
  end
end
extend(Cucumber::RbSupport::RbDsl)

Cucumber::StepMother.class_eval do
  def before_step #:nodoc:
    return if options[:dry_run]
    @programming_languages.each do |programming_language|
      programming_language.execute_before_step(@current_scenario)
    end
  end
end
