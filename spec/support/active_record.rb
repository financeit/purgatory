require 'active_record'
require 'generators/purgatory/templates/create_purgatories'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

ActiveRecord::Migration.create_table :widgets do |t|
  t.string :name
  t.timestamps
end

CreatePurgatories.new.migrate(:up)

RSpec.configure do |config|
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end