class CreateLists< ActiveRecord::Migration
  def change
    create_table :lists do |t|
    	t.integer :owner_id, null: false
    	t.string :owner_type, null: false
    	t.string :name, null: false
    	t.boolean :deleted, default: false
    	t.boolean :privacy_only, default: false
      t.timestamps
    end
  end
end
