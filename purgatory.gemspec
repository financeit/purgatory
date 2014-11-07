# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: purgatory 3.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "purgatory"
  s.version = "3.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Elan Dubrofsky"]
  s.date = "2014-11-07"
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
    "Rakefile",
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
  s.rubygems_version = "2.2.2"
  s.summary = "Allow changes to a model to be put in purgatory until they are approved"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.8.7"])
    else
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<bundler>, ["~> 1.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.8.7"])
    end
  else
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<bundler>, ["~> 1.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.8.7"])
  end
end

