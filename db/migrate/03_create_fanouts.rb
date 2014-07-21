class CreateFanouts < ActiveRecord::Migration
  def change
    create_table :fanouts do |t|
      t.integer :act_id, null: false
      t.string :act_type null: false
      t.integer :entity_id, null: false
      t.string :entity_type, null:false
      t.timestamps
    end
  end
end
