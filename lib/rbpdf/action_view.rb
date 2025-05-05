# frozen_string_literal: true
module Rbpdf
  module ActionView

  private
    def _rbpdf_compile_setup(dsl_setup = false)
      compile_support = Rbpdf::TemplateHandler::CompileSupport.new(controller)
      @rbpdf_options = compile_support.options
    end

  end
end

