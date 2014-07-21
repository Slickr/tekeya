module Tekeya
  module Feed
    	module Fanout
	      extend ActiveSupport::Concern
	      included do 
	      	belongs_to :act, :polymorphic => true, :autosave => true
	      	belongs_to :enitity, :polymorphic => true, :autosave => true
	   	 	end
    	end
    end
  end
end 