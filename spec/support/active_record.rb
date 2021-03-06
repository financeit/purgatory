require 'active_record'
require 'generators/purgatory/templates/create_purgatories'
require 'generators/purgatory/templates/add_performable_method_to_purgatories'
require 'purgatory/purgatory_module'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

ActiveRecord::Migration.create_table :widgets do |t|
  t.string :name
  t.integer :price
  t.string :original_name 
  t.timestamps
end

ActiveRecord::Migration.create_table :users do |t|
  t.string :name
  t.timestamps
end

ActiveRecord::Migration.create_table :animals do |t|
  t.string :name
  t.string :type
  t.integer :price 
  t.string :original_name 
end

ActiveRecord::Migration.create_table :items do |t|
  t.string :name
  t.integer :price
  t.string :original_name 
  t.timestamps
end

CreatePurgatories.new.migrate(:up)
AddPerformableMethodToPurgatories.new.migrate(:up)

PurgatoryModule.configure do |config|
  config.user_class_name = 'User'
end

RSpec.configure do |config|
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
