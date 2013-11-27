require 'active_support/core_ext/module/attribute_accessors.rb'

require 'purgatory/active_record_descendant_attribute_accessors'

module AttributeAccessorFields

  mattr_accessor :options

  def self.determine_attr_accessor_fields(obj)
    local_attributes = @@options[:local_attributes]

    variables = if local_attributes == :all
                  ActiveRecordDescendantAttributeAccessors.attr_accessor_instance_variables(obj)
                else
                  Array(local_attributes).map { |attribute|
                    attribute.to_s.prepend('@').to_sym
                  }
                end

    variables.inject({}) do |hash,var|
      hash[var] = obj.instance_variable_get(var)
      hash
    end
  end

end
