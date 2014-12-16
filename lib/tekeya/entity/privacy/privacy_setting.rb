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

          # Determines the set of entity which activities will be fanned out to.
          def will_fanout_activities_to
            if to_public
              # If public then will fan out to trackers
              entity.trackers
            elsif unrestricted_only
              # If unrestricted_only will fan out to trackers who are not in the restricted list
              restricted_members = entity.owned_lists.restricted_list.members
              entity.trackers - restricted_members
            elsif friends_only
              # If friends only will fan out to members in friends list
              entity.owned_lists.friends_list.members
            elsif is_custom
              # If custom, then will fanout to members who are in allowed lists and not in not allowed lists
              allowed_members = allowed_privacy_lists.map(&:members).flatten.uniq
              not_allowed_members = not_allowed_privacy_lists.map(&:members).flatten
              allowed_members.reject! {|member| not_allowed_members.include?(member)}
              allowed_members
            end  
          end
          # Determines whether an entity is able to view future activites
          def can_see_future_activities?(ent)
            # If the entity is blocked, then false
            return false if entity.blocks?(ent)
            return true if ent == entity
            if to_public
              # If set to public then any non-blocked entity will be able to see future activities
              true
            elsif unrestricted_only
              # If set to unrestricted_only then any entity which is not added to the restricteed list is allowed
              restricted_list = entity.owned_lists.restricted_list
              !restricted_list.has_member?(ent)
            elsif friends_only
              # If set to friends only, then only members in friends list are allowed
              entity.owned_lists.friends_list.has_member?(ent)
            elsif is_custom
              # If custom, then ent will be allowed if he's not a member in any of the not allowed lists,
              #=> and must be a member in any of the allowed lists
              not_allowed_privacy_lists.each do |list|
                return false if list.has_member?(ent)
              end
              allowed_privacy_lists.each do |list|
                return true if list.has_member?(ent)
              end
              false    
            end  
          end  

          # Creates a custom  allowed list from an array of entities.
          # The owner of the privacy settings wil be the owner of this list,
          #=> this list has a boolean variable set to true privacy_only: true
          #=> which is used to determine whether it is user created or just used for privacy
          def create_custom_allowed_list_from(entities)
            # entities.uniq is called to make sure no duplicates are allowed.
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
              custom_list.add_member(e)
            end
            custom_list
          end 
        end
      end  
    end
  end
end
