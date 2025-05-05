# frozen_string_literal: true
module Rbpdf
  module ActionController

    DEFAULT_RBPDF_OPTIONS = {:inline=>true}
      
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def rbpdf(options)
          rbpdf_options = breakdown_rbpdf_options options
          write_inheritable_hash(:rbpdf, rbpdf_options)
        end

      private

        def breakdown_rbpdf_options(options)
          rbpdf_options = options.dup
          rbpdf_options
        end
      end

      def rbpdf(options)
        @rbpdf_options ||= DEFAULT_RBPDF_OPTIONS.dup
        @rbpdf_options.merge! options
      end


    private

      def compute_rbpdf_options
        @rbpdf_options ||= DEFAULT_RBPDF_OPTIONS.dup
        @rbpdf_options.merge!(self.class.read_inheritable_attribute(:rbpdf) || {}) {|k,o,n| o}
        @rbpdf_options
      end
  end
end


