module Tekeya
  module Feed
    module List
	    extend ActiveSupport::Concern
	      
	      included do 
	      	belongs_to :owner, :polymorphic => true
	      	has_many :listings, :class_name => '::Tekeya::Listing'
	      	def members
	      		members = []
	      		listings.each do |listing|
	      			members << listing.entity
	      		end
	      		members
	      	end	

	      	def mark_as_deleted
	      		update_attribute(:deleted, true)
	      	end

	      	def has_member?(member)
	      		members.include?(member)
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