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

	      	def members
	      		listings(force_reload = true).map(&:entity)
	      	end	

	      	def mark_as_deleted
	      		update_attribute(:deleted, true)
	      	end

	      	def add_member(member)
	      		return false if has_member?(member)
	      		listings.create(entity: member)
	      	end

	      	def remove_member(member)
	      		return false unless has_member?(member)
	      		listing = listings.where(entity: member).first
	      		listing.destroy
	      	end	
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