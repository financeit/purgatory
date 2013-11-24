require 'active_record'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

ActiveRecord::Migration.create_table :widgets do |t|
  t.string :name
  t.timestamps
end


ActiveRecord::Migration.create_table :purgatories do |t|
  t.integer :soul_id
  t.string :soul_type
  t.integer :requester_id
  t.integer :approver_id
  t.datetime :approved_at
  t.string :changes_json

  t.timestamps
end

RSpec.configure do |config|
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end