class CreatePrivacySettings< ActiveRecord::Migration
  def change
    create_table :privacy_settings do |t|
    	t.integer :entity_id, null: false
    	t.string 	:entity_type, null: false
    	t.boolean :to_public, default: false
      t.boolean :friends_only, default: false
      t.boolean :unrestricted_only, default: false
      t.boolean :is_custom, default: false
      t.boolean :is_default, default: false
      t.timestamps
    end
  end
end
