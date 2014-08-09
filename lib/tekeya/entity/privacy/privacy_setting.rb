module Tekeya
  module Entity
    module Privacy
      module PrivacySetting
        extend ActiveSupport::Concern
        included do


          belongs_to :entity, polymorphic: true 
          validates_presence_of :entity
          has_many :allowed_privacy_listings, -> {where(:allowed => true)}, :class_name => '::Tekeya::PrivacyListing', dependent: :destroy
          has_many :not_allowed_privacy_listings, -> {where(:allowed => false)}, :class_name => '::Tekeya::PrivacyListing', dependent: :destroy
          has_many :allowed_privacy_lists, :through => :allowed_privacy_listings, :source => :privacy_list
          has_many :not_allowed_privacy_lists, :through => :not_allowed_privacy_listings, :source => :privacy_list
          has_many :using_activities, :class_name => '::Tekeya::Activity'
          def set_to_default
            update_attribute(:is_default, true)
          end

          def set_to_not_default
            update_attribute(:is_default, false)
          end

          def will_fanout_activities_to
            if to_public
              entity.trackers
            elsif unrestricted_only
              restricted_members = entity.owned_lists.restricted_list.members
              entity.trackers - restricted_members
            elsif friends_only
              entity.owned_lists.friends_list.members
            elsif is_custom
              allowed_members = allowed_privacy_lists.map(&:members).flatten.uniq
              not_allowed_members = not_allowed_privacy_lists.map(&:members).flatten
              allowed_members.reject! {|member| not_allowed_members.include?(member)}
              allowed_members
            end  
          end

          def can_see_future_activities?(ent)
            return false if entity.blocks?(ent)
            return true if ent == entity
            if to_public
              true
            elsif unrestricted_only
              restricted_list = entity.owned_lists.restricted_list
              !restricted_list.has_member?(ent)
            elsif friends_only
              entity.owned_lists.friends_list.has_member?(ent)
            elsif is_custom
              not_allowed_privacy_lists.each do |list|
                return false if list.has_member?(ent)
              end
              allowed_privacy_lists.each do |list|
                return true if list.has_member?(ent)
              end
              false    
            end  
          end  

          def create_custom_allowed_list_from(entities)
            custom_list = create_custom_privacy_list_from(entities.uniq, true)
            return false unless custom_list
            allowed_privacy_listings.create(privacy_list: custom_list, is_custom: true)
          end

          def create_custom_not_allowed_list_from(entities)
            custom_list = create_custom_privacy_list_from(entities.uniq, false)
            return false unless custom_list
            not_allowed_privacy_listings.create(privacy_list: custom_list, is_custom: true)
          end   

          private
          def privacy_key
            k = []
            k[0] = 'owner'
            k[1] = self.entity_id
            k[2] = self.entity_type
            k[3] = 'custom_privacy_list'
            k[4] = self.id.to_s

            k.join(':')
          end

          def create_custom_privacy_list_from(entities, allowed)
            name = privacy_key
            if allowed
              name += ':allowed'
            else
              name += ':not_allowed'
            end  
            custom_list = entity.owned_lists.create_list(name, true)
            entities.each do |e|
              unless e.is_tekeya_entity?
                custom_list.destroy
                return false
              end 
              entity.owned_lists.add_member_to_list(e, custom_list)
            end
            custom_list
          end 
        end
      end  
    end
  end
end
