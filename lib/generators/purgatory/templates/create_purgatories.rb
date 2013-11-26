class CreatePurgatories < ActiveRecord::Migration
  def change
    create_table :purgatories do |t|
      t.integer :soul_id
      t.string :soul_type
      t.integer :requester_id
      t.integer :approver_id
      t.datetime :approved_at
      t.string :requested_changes
      t.string :attr_accessor_fields

      t.timestamps
    end
  end
end
