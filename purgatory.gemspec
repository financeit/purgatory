# -*- encoding: utf-8 -*-
# stub: purgatory 6.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "purgatory"
  s.version = "6.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Elan Dubrofsky"]
  s.date = "2017-08-24"
  s.description = "Put your model changes in purgatory and allow them to remain lost souls until they are approved"
  s.email = "elan.dubrofsky@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.markdown"
  ]
  s.files = [
    ".document",
    ".rspec",
    ".travis.yml",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.markdown",
    "VERSION",
    "init.rb",
    "lib/generators/purgatory/purgatory_generator.rb",
    "lib/generators/purgatory/templates/add_performable_method_to_purgatories.rb",
    "lib/generators/purgatory/templates/create_purgatories.rb",
    "lib/purgatory.rb",
    "lib/purgatory/active_record_descendant_attribute_accessors.rb",
    "lib/purgatory/attribute_accessor_fields.rb",
    "lib/purgatory/purgatory.rb",
    "lib/purgatory/purgatory_module.rb",
    "purgatory.gemspec",
    "spec/purgatory_spec.rb",
    "spec/support/active_record.rb",
    "spec/support/animal.rb",
    "spec/support/item.rb",
    "spec/support/user.rb",
    "spec/support/widget.rb"
  ]
  s.homepage = "http://github.com/financeit/purgatory"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.2.5"
  s.summary = "Allow changes to a model to be put in purgatory until they are approved"

  if s.respond_to? :specification_version
    s.specification_version = 4
  end
end
