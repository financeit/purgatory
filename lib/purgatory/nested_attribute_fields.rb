module NestedAttributeFields
  def self.set_nested_attributes_to_save(klass, attrs)
    klass.instance_variable_set(:@nested_attributes_for_purgatory, attrs)
  end

  def self.get_nested_attributes_to_save(obj)
    current_class = obj.class
    while current_class.present?
      attrs = current_class.instance_variable_get(:@nested_attributes_for_purgatory)
      return attrs if attrs.present?
      current_class = current_class.superclass
    end
    nil
  end
end
