# frozen_string_literal: true
module Rbpdf
  module TemplateHandlers
    if defined?  ::ActionView::TemplateHandlers
      class Base < ::ActionView::TemplateHandlers::ERB
        def compile(template)
          src = "_rbpdf_compile_setup;" + super
        end
      end
    else # Rails3.x
      class Base < ::ActionView::Template::Handlers::ERB
        def compile(template)
          src = "_rbpdf_compile_setup;" + super
        end
      end
    end
  end
end


