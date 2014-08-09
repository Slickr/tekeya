module Tekeya
	module Entity
		module Privacy
			module Secureable
				extend ActiveSupport::Concern
				included do

					has_many :privacy_settings, as: :entity, class_name: "::Tekeya::PrivacySetting" do
						def restricted_list
							first.entity.owned_lists.restricted_list
						end	
						def default_privacy_setting
							where(:is_default => true).first
						end

						def set_default_to_public
							public_setting = create(to_public: true)
							set_default_privacy_setting_to(public_setting)		
						end

						def set_default_to_friends_only
							friends_only = create(friends_only: true)
							set_default_privacy_setting_to(friends_only)
						end

						def set_default_to_unrestricted_only
							unrestricted = create(unrestricted_only: true)
							unrestricted.not_allowed_privacy_lists << restricted_list
							set_default_privacy_setting_to(unrestricted)
						end	
						def set_default_to_custom(*args)
							options = args.extract_options!
							return false if options.empty?
							options[:is_custom] = true
							allowed_entities = options[:allowed_entities]
							not_allowed_entities = options[:not_allowed_entities]
							options.except!(:allowed_entities, :not_allowed_entities)
							custom = create(options)
							if allowed_entities
								custom.create_custom_allowed_list_from(allowed_entities)
							end

							if not_allowed_entities
								custom.create_custom_not_allowed_list_from(not_allowed_entities)
							end
							
							set_default_privacy_setting_to(custom)
						end		

						def copy_not_allowed_lists_to(privacy_setting)
							currently_not_allowed_lists = default_privacy_setting.not_allowed_privacy_lists
							currently_not_allowed_lists.each {|list| privacy_setting.not_allowed_privacy_lists << list}
							privacy_setting.save!
						end	

						def set_default_privacy_setting_to(privacy_setting)
							default_privacy_setting.set_to_not_default
							privacy_setting.set_to_default
						end
							
					  def init_privacy
							create(to_public: true, is_default: true)
					  end
 					 
					end
				end	
			end
		end
	end
end				