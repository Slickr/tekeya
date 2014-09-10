module Tekeya
  module Feed
    module List
	    extend ActiveSupport::Concern
	      
	      included do 
	      	belongs_to :owner, :polymorphic => true, autosave: true
	      	has_many :allowed_privacy_listings, -> {where(:allowed => true)}, :class_name => '::Tekeya::PrivacyListing'
	      	has_many :not_allowed_privacy_listings, -> {where(:allowed => false)}, :class_name => '::Tekeya::PrivacyListing'
	      	has_many :allowed_privacy_settings, :through => :allowed_privacy_listings, :source => :privacy_setting
	      	has_many :not_allowed_privacy_settings, :through => :not_allowed_privacy_listings, :source => :privacy_setting
	      	has_many :listings, :class_name => '::Tekeya::Listing', :dependent => :destroy

	      	validates_uniqueness_of :name, scope: [:owner_id, :owner_type], conditions: -> {where(deleted: false, privacy_only: false)}
	      	
	      	# Returns an {Array<entity>} who are the members of the list
	      	def members
	      		listings(force_reload = true).map(&:entity)
	      	end	

	      	# Lists should never be deleted as they are used in privacy settings, so they are marked as deleted only.
	      	def mark_as_deleted
	      		update_attribute(:deleted, true)
	      	end

	      	# Adds the given member to the list.
	      	def add_member(member)
	      		listings.create(entity: member)
	      	end

	      	# Removes the given member from the list if found.
	      	def remove_member(member)
	      		listing = listings.where(entity: member).first
	      		listing.destroy if listing.present?
	      	end	

	      	# Returns {Boolean}, true if the given entity is a member in the list.
	      	def has_member?(member)
	      		listings.exists?(entity: member)
	      	end	

	      	def deleted?
	      		deleted
	      	end	
	   	 	end

	   	module ClassMethods
      end
    end
  end
end 