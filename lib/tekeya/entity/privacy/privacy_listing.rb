module Tekeya
  module Entity
    module Privacy
      module PrivacyListing
        extend ActiveSupport::Concern
        included do

          belongs_to :privacy_list, :class_name => '::Tekeya::List'
          belongs_to :privacy_setting, :class_name => '::Tekeya::PrivacySetting'
          
        end
      end  
    end
  end
end
