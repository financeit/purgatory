class CreatePurgatories < ActiveRecord::Migration
  def change
    create_table :purgatories do |t|
      t.integer :soul_id
      t.string :soul_type
      t.integer :requester_id
      t.integer :approver_id
      t.datetime :approved_at
      t.text :requested_changes

      t.timestamps
    end
  end
end
