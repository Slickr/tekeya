module Tekeya
  module Feed
    module Fanout
	    extend ActiveSupport::Concern
	      
	      included do 
	      	belongs_to :act, :polymorphic => true
	      	belongs_to :enitity, :polymorphic => true
	   	 	end

	   	 	module ClassMethods
      end
    end
  end
end 