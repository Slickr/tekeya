module Tekeya
  module Feed
    module Listing
	    extend ActiveSupport::Concern
	      
	      included do 
	      	belongs_to :entity, :polymorphic => true
	      	belongs_to :list
	   	 	end

	   	module ClassMethods
      end
    end
  end
end 