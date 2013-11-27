require 'purgatory/active_record_descendant_attribute_accessors'

module PurgatoryModule
  extend ActiveSupport::Concern

  include ActiveRecordDescendantAttributeAccessors

  module ClassMethods
    def use_purgatory
      self.has_many :purgatories, as: :soul
    end
  end

  def purgatory!(requester = nil, options = {})
    return nil if self.invalid?
    return nil if Purgatory.pending_with_matching_soul(self).any? && options[:fail_if_matching_soul]
    Purgatory.create soul: self, requester: requester, attr_accessor_fields: determine_attr_accessor_fields
  end

  class Configuration
    attr_accessor :user_class_name
  end

  class << self
    def configure(&block)
      yield(configuration)
      configuration
    end

    def configuration
      @_configuration ||= Configuration.new
    end
  end

  private

  def determine_attr_accessor_fields
    hash = {}

    attr_accessor_instance_variables.each do |var|
      hash[var] = self.instance_variable_get(var)
    end

    hash
  end

end
