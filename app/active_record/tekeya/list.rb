module Tekeya
  class List < ::ActiveRecord::Base
    include ::Tekeya::Feed::List
  end
end