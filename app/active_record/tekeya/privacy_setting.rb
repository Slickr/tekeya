module Tekeya
  class PrivacySetting < ::ActiveRecord::Base
    include ::Tekeya::Entity::Privacy::PrivacySetting
  end
end