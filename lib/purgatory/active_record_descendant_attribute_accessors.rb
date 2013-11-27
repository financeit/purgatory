module ActiveRecordDescendantAttributeAccessors

  def self.attr_accessor_instance_variables(obj)
    include_ancestor_methods = false
    
    ancestors_before_active_record_base = obj.class.ancestors.take_while { |klass| klass != ActiveRecord::Base }

    instance_methods_of_ancestors_before_active_record_base = ancestors_before_active_record_base
                                                                .map { |klass| klass.instance_methods(include_ancestor_methods) }
                                                                .flatten

    setter_methods_of_ancestors_before_active_record_base = instance_methods_of_ancestors_before_active_record_base
                                                                .select { |meth| meth.to_s.last == '=' } 

    possible_instance_variables_from_setter_methods = setter_methods_of_ancestors_before_active_record_base
                                                                .map { |meth| meth.to_s.prepend('@').chop.to_sym }

    obj.instance_variables & possible_instance_variables_from_setter_methods
  end

  def self.determine_attr_accessor_fields(obj)
    hash = {}

    attr_accessor_instance_variables(obj).each do |var|
      hash[var] = obj.instance_variable_get(var)
    end

    hash
  end

end
