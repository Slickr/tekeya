module Tekeya
  module Feed
    module Listing
	    extend ActiveSupport::Concern
	      
	    included do 
	      belongs_to :entity, :polymorphic => true
	      belongs_to :list


	      validates_presence_of :entity, :list
	      validate :is_tekeya_entity
	     	validate :tracks_owner
	      validates :entity_id, uniqueness: { scope: [:list_id, :entity_type]}

	      def is_tekeya_entity
	      	unless entity.respond_to?(:is_tekeya_entity?)
	      		errors.add(:self, "The given entity is not a tekeya entity.")
	      	end
	      end

	      def tracks_owner
	      	unless entity.tracks?(list.owner)
	      		errors.add(:self, "The given entity does not track the list owner")
	      	end
	      end

	   	end
    end
  end
end 