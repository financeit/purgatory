# Requires
require 'rails/generators'
require 'rails/generators/migration'

class PurgatoryGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  def self.source_root
    @source_root ||= File.join(File.dirname(__FILE__), 'templates')
  end

  def self.next_migration_number(dirname)
    if ActiveRecord.timestamped_migrations
      Time.new.utc.strftime("%Y%m%d%H%M%S")
    else
      "%.3d" % (current_migration_number(dirname) + 1)
    end
  end

  def create_migration_file
    ['create_purgatories', 'add_performable_method_to_purgatories'].each do |filename|
      unless self.class.migration_exists?("db/migrate", "#{filename}").present?
        migration_template "#{filename}.rb.erb", "db/migrate/#{filename}.rb"
      end
    end
  end

  def migration_version
    format("[%d.%d]", ActiveRecord::VERSION::MAJOR, ActiveRecord::VERSION::MINOR)
  end

  def create_initializer_file
    create_file 'config/initializers/purgatory.rb', <<-eos
PurgatoryModule.configure do |config|
  config.user_class_name = 'User'
end

require 'purgatory/purgatory'
    eos
  end
end
