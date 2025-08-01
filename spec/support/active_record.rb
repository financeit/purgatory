require 'active_record'
require 'purgatory/purgatory_module'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

ActiveRecord.use_yaml_unsafe_load = true

ActiveRecord::Encryption.configure(
  primary_key: 'abc123',
  deterministic_key: 'def456',
  key_derivation_salt: 'ghi789',
)

ActiveRecord::Migration.create_table :widgets do |t|
  t.string :name
  t.string :token, limit: 510
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

ActiveRecord::Migration.create_table :purgatories do |t|
    t.integer :soul_id
    t.string :soul_type
    t.integer :requester_id
    t.integer :approver_id
    t.datetime :approved_at
    t.text :requested_changes
    t.text :attr_accessor_fields
    t.text :performable_method
    t.timestamps

    t.index [:soul_id, :soul_type]
    t.index :requester_id
    t.index :approver_id
end

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
