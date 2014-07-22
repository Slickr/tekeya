module Tekeya
  module Feed
    module Fanout
	    extend ActiveSupport::Concern
	      
	      included do 
	      	belongs_to :act, :polymorphic => true, autosave: true
	      	belongs_to :entity, :polymorphic => true, autosave: true
	   	 	end

	   	module ClassMethods
      end
    end
  end
end 