require 'purgatory/attribute_accessor_fields'

module PurgatoryModule
  extend ActiveSupport::Concern

  module ClassMethods
    def use_purgatory(options={})
      AttributeAccessorFields.set_local_attributes_to_save(self,options[:local_attributes]) 
      self.has_many :purgatories, as: :soul
    end
  end

  def purgatize(requester = nil, options = {})
    Purgatization.new(self, requester, options)
  end

  def purgatory!(requester = nil, options = {})
    return nil if self.invalid?
    return nil if Purgatory.pending_with_matching_soul(self).any? && options[:fail_if_matching_soul]
    Purgatory.create soul: self, requester: requester, attr_accessor_fields: AttributeAccessorFields.determine_attr_accessor_fields(self)
  end

  class Configuration
    attr_accessor :user_class_name
  end

  class Purgatization
    def initialize(soul, requester, options)
      @soul = soul
      @requester = requester
      @options = options
    end

    def method_missing(method, *args)
      return nil if Purgatory.pending_with_matching_soul(@soul).any? && @options[:fail_if_matching_soul]
      Purgatory.create soul: @soul, requester: @requester, performable_method: {method: method.to_sym, args: args}
    end
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

end
