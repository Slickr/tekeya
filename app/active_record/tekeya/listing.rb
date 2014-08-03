module Tekeya
  class Listing < ::ActiveRecord::Base
    include ::Tekeya::Feed::Listing
  end
end