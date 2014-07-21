class Fan < ActiveRecord::Base
	include Tekeya::Feed::Fanout
end
