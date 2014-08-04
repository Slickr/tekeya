module Tekeya
  module Feed
    module List
	    extend ActiveSupport::Concern
	      
	      included do 
	      	belongs_to :owner, :polymorphic => true, autosave: true
	      	has_many :listings, :class_name => '::Tekeya::Listing', :dependent => :destroy
	      	def members
	      		listings(force_reload = true).map(&:entity)
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