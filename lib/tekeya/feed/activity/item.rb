module Tekeya
  module Feed
    module Activity
      class Item
        attr_reader :activity_id, :activity_type, :attachments, :actor, :author, :timestamp, :activity_privacy_setting, :activity_customised_fanout

        def initialize(activity_id, activity_type, activity_privacy_setting, activity_customised_fanout,attachments, actor, author, timestamp)
          @activity_id = activity_id
          @activity_type = activity_type
          @activity_privacy_setting = activity_privacy_setting
          @activity_customised_fanout = activity_customised_fanout
          @attachments = attachments
          @actor = actor
          @author = author
          @timestamp = timestamp
        end

        def can_be_viewed_by?(entity)
          @activity_privacy_setting.can_see_future_activities?(entity)
        end
 

        # Builds a feed item from a redis activity
        # 
        # @param  [String] key the aggregate key of the activity
        # @param  [Tekeya::Entity] act_actor the activty actor; when nil the actor is retrieved from the aggregate key
        # @return [Tekeya::Feed::Activity::Item] the feed item
        def self.from_redis(key, act_actor = nil, act_privacy = nil)
          key_components  = key.split(':')
          
          act_id          = key_components[1]
          act_type        = key_components[6].to_sym
          act_time        = Time.at(key_components[7].to_i)
          act_custom_fan  = key_components[8]
          act_privacy_id  = key_components[9] 
          
          if act_actor.nil?
            actor_class = key_components[2].safe_constantize
            act_actor = actor_class.where(:"#{actor_class.entity_primary_key}" => key_components[3]).first
          end

          if act_privacy.nil?
            act_privacy = ::Tekeya::PrivacySetting.find(act_privacy_id)
          end  

          act_author = unless key_components[2] == key_components[4] && key_components[3] == key_components[5]
            author_class = key_components[4].safe_constantize
            author_class.where(:"#{actor_class.entity_primary_key}" => key_components[5]).first
          else
            act_actor
          end

          act_attachments = ::Tekeya.redis.smembers(key).map{|act| 
            ActiveSupport::JSON.decode(act)
          }.map{|att| 
            att['attachable_type'].safe_constantize.find att['attachable_id']
            
          }

          return self.new(act_id, act_type, act_privacy, act_custom_fan, act_attachments, act_actor, act_author, act_time)
        end

        # Builds a feed item a DB activity
        # 
        # @param  [Tekeya::Activity] activity the source activity
        # @param  [Tekeya::Entity] act_actor the activty actor; when nil the actor is retrieved from the activity
        # @return [Tekeya::Feed::Activity::Item] the feed item
        def self.from_db(activity, act_actor = nil)
          act_id            = activity.id.to_s
          act_type          = activity.activity_type.to_sym
          act_privacy       = activity.privacy_setting
          act_custom_fan    = activity.customised_fanout
          act_time          = activity.created_at
          act_actor       ||= activity.entity
          act_author        = activity.author
          act_attachments   = activity.attachments.map(&:attachable)

          return self.new(act_id, act_type, act_privacy, act_custom_fan, act_attachments, act_actor, act_author, act_time)
        end
      end
    end
  end
end