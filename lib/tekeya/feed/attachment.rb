module Tekeya
  module Feed
    module Attachment
      extend ActiveSupport::Concern

      included do
        belongs_to :attache, polymorphic: true, autosave: true
        belongs_to :attachable, polymorphic: true, autosave: true
        belongs_to :notification_attache, polymorphic: true, autosave: true

        include ActiveModel::Serializers::JSON
        attr_accessible :attache, :attachable, :notification_attache
      end

      module ClassMethods
      end

    end
  end
end
