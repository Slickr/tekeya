class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities do |t|
      t.string  :activity_type, null: false
      t.integer :entity_id, null: false
      t.string  :entity_type, null: false
      t.integer :author_id, null: false
      t.string  :author_type, null: false
      t.boolean :customised_fanout, default: false
      t.integer :fan_to, default: 0
      t.timestamps
    end
  end
end
