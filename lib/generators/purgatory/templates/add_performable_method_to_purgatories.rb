class AddPerformableMethodToPurgatories < ActiveRecord::Migration
  def change
    add_column :purgatories, :performable_method, :text
  end
end
