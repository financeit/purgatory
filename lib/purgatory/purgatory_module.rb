module PurgatoryModule
  extend ActiveSupport::Concern

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

  def attr_accessor_instance_variables
    include_ancestor_methods = false
    
    ancestors_before_active_record_base = self.class.ancestors.take_while { |klass| klass != ActiveRecord::Base }

    instance_methods_of_ancestors_before_active_record_base = ancestors_before_active_record_base
                                                                .map { |klass| klass.instance_methods(include_ancestor_methods) }
                                                                .flatten

    setter_methods_of_ancestors_before_active_record_base = instance_methods_of_ancestors_before_active_record_base
                                                                .select { |meth| meth.to_s.last == '=' } 

    possible_instance_variables_from_setter_methods = setter_methods_of_ancestors_before_active_record_base
                                                                .map { |meth| meth.to_s.prepend('@').chop.to_sym }

    instance_variables & possible_instance_variables_from_setter_methods
  end
end
