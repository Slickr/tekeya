class CreateListings < ActiveRecord::Migration
  def change
    create_table :listings do |t|
      t.integer :list_id, null: false
      t.integer :entity_id, null: false
      t.string :entity_type, null: false
      t.timestamps
    end
  end
end
