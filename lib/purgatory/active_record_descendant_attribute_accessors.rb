module ActiveRecordDescendantAttributeAccessors

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
