module Tekeya
  # Represents a tekeya entity, the main building block of the engine
  module Entity
    require 'will_paginate/array'
    extend ActiveSupport::Concern

    included do
      # Entities are attachable to activities
      include ::Tekeya::Feed::Attachable
      include ::Tekeya::Entity::Privacy::Secureable
      # which field should be used as a primary key
      class_attribute :entity_primary_key
      after_create do |entity|
        entity.owned_lists.init_lists
        entity.privacy_settings.init_privacy
      end  
      # default primary key
      define_tekeya_primary_key :id
      
      has_many :listings, as: :entity, class_name: "::Tekeya::Listing", dependent: :destroy   

      # Lists in which the entity is a member in.
      has_many :member_lists, :through => :listings, class_name: "::Tekeya::List", source: :list do

        # Returns {Boolean}, true if entity is member in any list owned by {params entity}, false otherwise.
        def any_owned_by?(entity)
          owned_by(entity).any?
        end

        # Returns {Collection}, all lists in which entity is a member in and owned by {params entity}
        def owned_by(entity)
          where(:owner_id => entity.id, :owner_type => entity.class.to_s)
        end

        # Returns {Boolean}, true if entity successfully left {params list}, false otherwise.
        def leave(list)
          delete(list)
        end  
      end 

      # Lists owned by the entity.
      has_many :owned_lists, as: :owner, class_name: "::Tekeya::List", :dependent => :destroy do

        # Lists which are created by the entity and maybe used generally.
        def general_usage
          where(privacy_only: false)
        end

        # Lists created by the privacy settings of the entity.
        def privacy_only
          where(privacy_only: true) 
        end

        # Initializes the lists for the entity, those lists cannot be deleted.
        def init_lists
          create(name: 'Friends')
          create(name: 'Restricted')
        end
        # Returns the restricted list.
        def restricted_list
          find_by(name: 'Restricted')
        end

        # Returns the entity's friends list.
        def friends_list
          find_by(name: 'Friends')
        end  

        def add_entity_to_friends_list(entity)
          friends_list.add_member(entity)
        end

        def add_entity_to_restricted_list(entity)
          restricted_list.add_member(entity)
        end

        # @[Params name] the name of the list, @[Params privacy_only] whether the list is privacy usage only or not, defaults to false.
        def create_list(name, privacy_only=false)
         create(name: name, privacy_only: privacy_only)
        end

      end  
      # define the relation with the activity

      has_many :fanouts, as: :entity, class_name: "::Tekeya::Fanout"
      has_many :activities, as: :entity, class_name: "::Tekeya::Activity", dependent: :destroy do
        # Returns activities dating up to 10 days in the past
        def recent
          c = unless ::Tekeya::Configuration.instance.feed_storage_orm.to_sym == :mongoid
            where("created_at > ?", 1.month.ago)
          else
            criteria.where(:created_at.gte => 1.month.ago)
            # .desc('created_at')
          end
          c = yield c if block_given?
          c
        end

        # Any method missing invoked on activities is considered a new activity
        def method_missing(meth, *args, &block)
          options = args.extract_options!
          bool_args = args.map{|arg| arg.respond_to?(:is_tekeya_attachable)}.uniq
          is_activity = bool_args.length == 1 && bool_args.first == true

          if is_activity
            attachments = []
            args.each do |attachable|
              attachments << ::Tekeya::Attachment.new(attachable: attachable)
            end
            create(activity_type: meth, attachments: attachments, group_with_recent: options[:group].nil? ? true : options[:group], author: options[:author], customised_fanout: options[:customised_fanout].nil? ? false : options[:customised_fanout], privacy_setting: options[:privacy_setting])
          else
            super
          end
        end
      end

      has_many :notifications, as: :entity, class_name: "::Tekeya::Notification", dependent: :destroy do
        def unread
          unless ::Tekeya::Configuration.instance.feed_storage_orm.to_sym == :mongoid
            where(read: false).order('created_at DESC')
          else
            criteria.where(read: false).desc('created_at')
          end
        end

        # Any method missing invoked on activities is considered a new activity
        def method_missing(meth, *args, &block)
          options = args.extract_options!
          bool_args = args.map{|arg| arg.respond_to?(:is_tekeya_attachable)}.uniq
          is_notification = bool_args.length == 1 && bool_args.first == true

          if is_notification
            actors = []

            args.each do |attachable|
              actors << ::Tekeya::Attachment.new(attachable: attachable)
            end

            subject = @association.nil? ? base : @association.owner
            create(notification_type: meth, subject: options[:subject].nil? ? subject : options[:subject], actors: actors, group_with_recent: options[:group].nil? ? true : options[:group])
          else
            super
          end
        end
      end

      # define some callbacks
      define_callbacks :track_entity, :untrack_entity, :join_group, :leave_group, :block_entity, :unblock_entity
    end

    module ClassMethods
      # Sets an after callback to be run after an entity is tracked
      #
      # @param [Symbol, String] callback the method to be run
      def after_tracking_entity(callback)
        set_callback :track_entity, :after, callback
      end

      # Sets an after callback to be run after an entity is untracked
      #
      # @param [Symbol, String] callback the method to be run
      def after_untracking_entity(callback)
        set_callback :untrack_entity, :after, callback
      end

      # Sets an after callback to be run after a group is joined
      #
      # @param [Symbol, String] callback the method to be run
      def after_joining_group(callback)
        set_callback :join_group, :after, callback
      end

      # Sets an after callback to be run after a group is left
      #
      # @param [Symbol, String] callback the method to be run
      def after_leaving_group(callback)
        set_callback :leave_group, :after, callback
      end

      # Sets an after callback to be run after an entity is blocked
      #
      # @param [Symbol, String] callback the method to be run
      def after_blocking_entity(callback)
        set_callback :block_entity, :after, callback
      end

      # Sets an after callback to be run after an entity is unblocked
      #
      # @param [Symbol, String] callback the method to be run
      def after_unblocking_entity(callback)
        set_callback :unblock_entity, :after, callback
      end

      # Defines the primary key for Tekeya to use in relations
      #
      # @param [Symbol] key the field to use as a primary key
      def define_tekeya_primary_key(key)
        self.entity_primary_key = key
      end
    end

    # Tracks the given entity and copies it's recent feed to the tracker feed
    #
    # @param [Entity] entity the entity to track
    # @param [Boolean] notify determines whether the tracked entity should be notified
    # @return [Boolean]
    def track(entity, notify=true)
      run_callbacks :track_entity do
        check_if_tekeya_entity(entity)
        raise ::Tekeya::Errors::TekeyaRelationAlreadyExists.new("Already tracking #{entity}") if self.tracks?(entity)

        ret = add_tekeya_relation(self, entity, :tracks)

        if ret
        # ::Resque.enqueue(::Tekeya::Feed::Activity::Resque::FeedCopy, entity.profile_feed_key, self.feed_key)
          # check if entity tracks self too; if true, the entity will automatically be added to self Friends list and self will be added to the entity's Friends list
          if entity.tracks?(self)
            self.owned_lists.add_entity_to_friends_list(entity)
            entity.owned_lists.add_entity_to_friends_list(self)
          end 
          activity = self.activities.followed(entity)
          entity.notifications.followed_by self if notify
        end

        return ret
      end
    end

    # Return a list of entities being tracked by this entity
    #
    # @param  [String] type used to return a certain type of entities being tracked
    # @return [Array] the entities tracked by this entity
    def tracking(type = nil)
      tekeya_relations_of(self, :tracks, type)
    end

    def tracking_with_filter(field, value, type=nil)
      tekeya_relations_with_filter(self, :tracks, type, false, field, value)
    end 
    # Returns a list of entities tracking this entity
    #
    # @param  [String] type used to return a certain type of entities being tracked
    # @return [Array] the entities tracking this entity
    def trackers(type = nil)
      tekeya_relations_of(self, :tracks, type, true)
    end

    def trackers_with_filter(field, value, type = nil)
      tekeya_relations_with_filter(self, :tracks, type, true, field, value)
    end  

    # Checks if this entity is tracking the given entity
    #
    # @param  [Entity] entity the entity to check
    # @return [Boolean] true if this entity is tracking the given entity, false otherwise
    def tracks?(entity)
      check_if_tekeya_entity(entity)
      tekeya_relation_exists?(self, entity, :tracks)
    end

    # Untracks the given entity and deletes recent activities of the untracked entity from this entity's feed
    #
    # @param [Entity] entity the entity to untrack
    # @return [Boolean]
    def untrack(entity)
      run_callbacks :untrack_entity do
        check_if_tekeya_entity(entity)
        raise ::Tekeya::Errors::TekeyaRelationNonExistent.new("Can't untrack an untracked entity") unless self.tracks?(entity)
        
        # If self is member in any list owned by the untracked entity, self should leave the list.
        if self.member_lists.any_owned_by?(entity)
          lists = self.member_lists.owned_by(entity)
          lists.each do |list|
            self.member_lists.leave(list)
          end  
        end

        # Check if entity is member in self's friends_list; if true, the entity will be removed
        friends_list = owned_lists.friends_list
        if friends_list.has_member?(entity)
          friends_list.remove_member(entity)
        end  
        ret = delete_tekeya_relation(self, entity, :tracks)
        
        ::Resque.enqueue(::Tekeya::Feed::Activity::Resque::UntrackFeed, entity.profile_feed_key, self.feed_key) if ret

        return ret
      end
    end

    # Blocks the given entity and removes any tracking relation between both entities
    #
    # @param [Entity] entity the entity to block
    # @return [Boolean]
    def block(entity)
      run_callbacks :block_entity do
        check_if_tekeya_entity(entity)
        raise ::Tekeya::Errors::TekeyaRelationAlreadyExists.new("Already blocking #{entity}") if self.blocks?(entity)

        unless entity.is_tekeya_group?
          self.untrack(entity) if self.tracks?(entity)
          entity.untrack(self) if entity.tracks?(self)
        end

        add_tekeya_relation(self, entity, :blocks)
      end
    end

    # Returns a list of entities blocked by this entity
    #
    # @param  [String] type used to return a certain type of entities blocked
    # @return [Array] the entities blocked by this entity
    def blocked(type = nil)
      tekeya_relations_of(self, :blocks, type)
    end

    # Checks if this entity is blocking the given entity
    #
    # @param  [Entity] entity the entity to check
    # @return [Boolean] true if this entity is blocking the given entity, false otherwise
    def blocks?(entity)
      check_if_tekeya_entity(entity)
      tekeya_relation_exists?(self, entity, :blocks)
    end

    # Unblock the given entity
    #
    # @param [Entity] entity the entity to unblock
    # @return [Boolean]
    def unblock(entity)
      run_callbacks :unblock_entity do
        check_if_tekeya_entity(entity)
        raise ::Tekeya::Errors::TekeyaRelationNonExistent.new("Can't unblock an unblocked entity") unless self.blocks?(entity)

        delete_tekeya_relation(self, entity, :blocks)
      end
    end

    # Joins the given group and tracks it
    #
    # @note will automatically track the group
    # @param [Group] group the group to track
    # @param [Boolean] track_also if set to false automatic tracking is disabled
    # @param [Boolean] notify determines whether the joined group's owner should be notified
    # @return [Boolean]
    def join(group, track_also = true, notify=true)
      run_callbacks :join_group do
        check_if_tekeya_group(group)
        raise ::Tekeya::Errors::TekeyaRelationAlreadyExists.new("Already a member of #{group}") if self.member_of?(group)

        ret = add_tekeya_relation(self, group, :joins)
        ret &= self.track(group, false) if track_also && !self.tracks?(group) && ret
        
        if ret
          activity = self.activities.joined(group)
          group.owner.notifications.joined_by self, subject: group if notify
        end
        return ret
      end
    end

    # Return a list of groups joined by this entity
    #
    # @param  [String] type used to return a certain type of groups joined
    # @return [Array] the groups joined by this entity
    def groups(type = nil)
      tekeya_relations_of(self, :joins, type)
    end

    # Checks if this entity is a member of the given group
    #
    # @param  [Group] group the group to check
    # @return [Boolean] true if this entity is a member of the given group, false otherwise
    def member_of?(group)
      check_if_tekeya_group(group)
      tekeya_relation_exists?(self, group, :joins)
    end

    # Leaves the given group and untracks it
    #
    # @param [Group] group the group to untrack
    # @return [Boolean]
    def leave(group)
      run_callbacks :leave_group do
        check_if_tekeya_group(group)
        raise ::Tekeya::Errors::TekeyaRelationNonExistent.new("Can't leave an unjoined group") unless self.member_of?(group)

        ret = delete_tekeya_relation(self, group, :joins)
        ret &= self.untrack(group) if self.tracks?(group) && ret

        return ret
      end
    end

    def profile_feed_for(entity, &blck)
      feeds = profile_feed(&blck)
      feeds.select! {|feed| feed.can_be_viewed_by?(entity)}
      feeds
    end  

    # Returns the entity's recent activities
    #
    # @return [Array] the list of recent activities by this entity
    def profile_feed(page=1, per_page=16, &blck)
      acts = []
      pkey = self.profile_feed_key
      recent_activities_count = ::Tekeya.redis.zcard(pkey)

      # Check if the cache is not empty
      if recent_activities_count > 0 && !block_given?
        # Retrieve the aggregate keys from redis
        acts_keys = ::Tekeya.redis.zrevrange(pkey, 0, -1).paginate(:page => page, :per_page => per_page)
        # Retrieve the aggregates
        acts_keys.compact.each do |act_key|
          # Make `from_redis` only hit the db if author != entity
          key_components = act_key.split(':')
          actor = if key_components[4] == self.class.to_s && key_components[5] == self.entity_primary_key
            self
          end
          acts << ::Tekeya::Feed::Activity::Item.from_redis(act_key, actor)
          # p "   Getting Act Key: #{current_act.to_s}"
          p "|>>"
          return acts.compact
        end
      else
        # Retrieve the activities from the DB
        acts_list = []
        db_recent_activities = self.activities.recent
        db_recent_activities.each do |activity|
          acts_list << [activity, activity.author]
        end
        acts_list.sort { |a, b| b[0].created_at <=> a[0].created_at }.paginate(:page => page, :per_page => per_page)
        acts_list.each do |act|
          acts << ::Tekeya::Feed::Activity::Item.from_db(act[0], act[1])
        end
        p "|>>"
        return acts.compact
      end

      # return acts.sort { |a, b| b.timestamp <=> a.timestamp }
    end
    
    # Returns the entity's feed
    #
    # @return [Array] the list of activities for the entities tracked by this entity
    def feed(page=1, per_page=16, &blck)
      acts = []
      fkey = self.feed_key
      recent_activities_count = ::Tekeya.redis.zcard(fkey)
      # Check if the cache is not empty
      if recent_activities_count > 0 && !block_given?
        p "Getting Entity #{self.id} feeds from Redis:"
        # Retrieve the aggregate keys from redis
        acts_keys = ::Tekeya.redis.zrevrange(fkey, 0, -1).paginate(:page => page, :per_page => per_page)
        # Retrieve the aggregates
        acts_keys.compact.each do |act_key|
          p "   Getting Act Key: #{act_key} |>>"
          # Make `from_redis` only hit the db if author != entity
          key_components = act_key.split(':')
          actor = if key_components[4] == self.class.to_s && key_components[5] == self.entity_primary_key
            self
          end
          acts << ::Tekeya::Feed::Activity::Item.from_redis(act_key, actor)
          # p "   Getting Act Key: #{current_act.to_s}"
          p "|>>"
          return acts.compact

          # (acts << current_act) if current_act.present? 
        end
      else
        p "Getting Entity #{self.id} feeds from DB:"
        # Retrieve the activities from the DB
        acts_list = []
        self.tracking.each do |tracker|
          db_recent_activities = tracker.activities.recent
          db_recent_activities.each do |activity|
            acts_list << [activity, tracker]
          end
        end
        acts_list.sort { |a, b| b[0].created_at <=> a[0].created_at }.paginate(:page => page, :per_page => per_page)
        acts_list.each do |act|
          acts << ::Tekeya::Feed::Activity::Item.from_db(act[0], act[1])
        end
        p "|>>"
        return acts.compact
      end
      # return acts.sort { |a, b| b.timestamp <=> a.timestamp }.paginate(:page => page, :per_page => per_page)
    end


    # @private
    # Returns a unique key for the entity's profile feed in redis
    def profile_feed_key
      "#{self.class.name}:#{self.send(self.entity_primary_key)}:profile:feed"
    end

    # @private
    # Returns a unique key for the entity's feed in redis
    def feed_key
      "#{self.class.name}:#{self.send(self.entity_primary_key)}:feed"
    end

    # A method to identify the entity
    #
    # @return [Boolean] true
    def is_tekeya_entity?
      return true
    end

    # A method to identify the entity as a non group
    #
    # @return [Boolean] false
    def is_tekeya_group?
      return false
    end



    private

    # @private
    # Checks if the given argument is an entity and raises an error if its not
    def check_if_tekeya_entity(entity)
      raise ::Tekeya::Errors::TekeyaNonEntity.new("Supplied argument is not a Tekeya::Entity") unless entity.present? && entity.is_tekeya_entity?
    end

    # @private
    # Checks if the given argument is a group and raises an error if its not
    def check_if_tekeya_group(group)
      raise ::Tekeya::Errors::TekeyaNonGroup.new("Supplied argument is not a Tekeya::Entity::Group") unless group.present? && group.is_tekeya_group?
    end

    # @private
    # Adds a rebat relation
    def add_tekeya_relation(from, to, type)
      ::Tekeya.relations.add(from.send(from.class.entity_primary_key), from.class.name, to.send(to.class.entity_primary_key), to.class.name, 0, type)
    end

    # @private
    # Deletes a rebat relation
    def delete_tekeya_relation(from, to, type)
      ::Tekeya.relations.delete(from.send(from.class.entity_primary_key), from.class.name, to.send(to.class.entity_primary_key), to.class.name, type)
    end

    # @private
    # Retrieves rebat relations
    def tekeya_relations_of(from, relation_type, entity_type, reverse = false)
      result_entity_class = entity_type.safe_constantize if entity_type
      relations = unless reverse
        ::Tekeya.relations.where(from.send(from.class.entity_primary_key), from.class.name, nil, entity_type, relation_type).entries.map do |entry|
          entity_class = result_entity_class || entry.toEntityType.safe_constantize
          entity_class.where(:"#{entity_class.entity_primary_key}" => entry.toEntityId).first
        end
      else
        ::Tekeya.relations.where(nil, entity_type, from.send(from.class.entity_primary_key), from.class.name, relation_type).entries.map do |entry|
          entity_class = result_entity_class || entry.fromEntityType.safe_constantize
          entity_class.where(:"#{entity_class.entity_primary_key}" => entry.fromEntityId).first
        end
      end
      relations.compact
    end

    def tekeya_relations_with_filter(from, relation_type, entity_type, reverse = false, field, value)
      result_entity_class = entity_type.safe_constantize if entity_type
        relations = unless reverse
          ::Tekeya.relations.where(from.send(from.class.entity_primary_key), from.class.name, nil, entity_type, relation_type).entries.map do |entry|
            entity_class = result_entity_class || entry.toEntityType.safe_constantize
            entity_class.where(:"#{entity_class.entity_primary_key}" => entry.toEntityId).where("#{field} LIKE ?", "#{value}%").first
          end
        else
          ::Tekeya.relations.where(nil, entity_type, from.send(from.class.entity_primary_key), from.class.name, relation_type).entries.map do |entry|
            entity_class = result_entity_class || entry.fromEntityType.safe_constantize
            entity_class.where(:"#{entity_class.entity_primary_key}" => entry.fromEntityId).where("#{field} LIKE ?", "#{value}%").first
          end
        end
      relations.compact
    end

    # @private
    # Checks if a rebat relation exists
    def tekeya_relation_exists?(from, to, type)
      !::Tekeya.relations.where(from.send(from.class.entity_primary_key), from.class.name, to.send(to.class.entity_primary_key), to.class.name, type).entries.empty?
    end
  end
end
