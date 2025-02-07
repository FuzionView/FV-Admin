# This is a ChatGPT backport of the the Rails 7.1 normalizes method. It
# can be removed on upgrade to Rails 7.1
module Normalization
  extend ActiveSupport::Concern

  included do
    class_attribute :_normalizations, instance_writer: false, default: {}
    before_validation :apply_normalizations
  end

  class_methods do
    def normalizes(*attributes, with:, apply_to_nil: false)
      self._normalizations = _normalizations.merge(attributes.map { |attr| [attr, { proc: with, apply_to_nil: apply_to_nil }] }.to_h)

      attributes.each do |attribute|
        define_method("#{attribute}=") do |value|
          normalized_value = self.class.normalize_attribute(attribute, value, with, apply_to_nil)
          super(normalized_value)
        end

        define_singleton_method("find_by_#{attribute}") do |value|
          normalized_value = normalize_attribute(attribute, value, with, apply_to_nil)
          super(normalized_value)
        end

        define_singleton_method("find_or_create_by_#{attribute}") do |value|
          normalized_value = normalize_attribute(attribute, value, with, apply_to_nil)
          super(normalized_value)
        end

        define_singleton_method("find_or_initialize_by_#{attribute}") do |value|
          normalized_value = normalize_attribute(attribute, value, with, apply_to_nil)
          super(normalized_value)
        end
      end
    end

    def normalize_attribute(attribute, value, normalization_proc, apply_to_nil)
      return value if value.nil? && !apply_to_nil
      normalization_proc.call(value)
    end
  end

  private

  def apply_normalizations
    self.class._normalizations.each do |attribute, options|
      value = read_attribute(attribute)
      normalized_value = self.class.normalize_attribute(attribute, value, options[:proc], options[:apply_to_nil])
      write_attribute(attribute, normalized_value)
    end
  end
end

