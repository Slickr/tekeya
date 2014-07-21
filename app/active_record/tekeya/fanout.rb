module Tekeya
  class Fanout < ::ActiveRecord::Base
    include ::Tekeya::Feed::Fanout
  end
end