module Tekeya
  module Feed
    module Listing
	    extend ActiveSupport::Concern
	      
	      included do 
	      	belongs_to :entity, :polymorphic => true, autosave: true
	      	belongs_to :list, autosave: true
	   	 	end

	   	module ClassMethods
      end
    end
  end
end 