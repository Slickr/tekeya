class CreatePrivacyListings< ActiveRecord::Migration
  def change
    create_table :privacy_listings do |t|
    	t.integer :privacy_list_id, null: false
    	t.integer :privacy_setting_id, null: false
    	t.boolean :allowed, null: false
    	t.boolean :is_custom, default: false
      t.timestamps
    end
  end
end
