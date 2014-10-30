class CreatePurgatories < ActiveRecord::Migration
  def change
    create_table :purgatories do |t|
      t.integer :soul_id
      t.string :soul_type
      t.integer :requester_id
      t.integer :approver_id
      t.datetime :approved_at
      t.text :requested_changes
      t.text :attr_accessor_fields
      t.text :performable_method

      t.timestamps
    end
    
    add_index :purgatories, [:soul_id, :soul_type]
    add_index :purgatories, :requester_id
    add_index :purgatories, :approver_id
  end
end
