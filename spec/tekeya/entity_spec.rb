require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Tekeya" do
  describe "Entity" do
    before :each do
      @user = Fabricate(:user)
      @user2 = Fabricate(:user)
      @user5 = Fabricate(:user)
      @user4 = Fabricate(:user)
      @group = Fabricate(:group)
    end

    it "should inherit all the relations and feed methods" do
      # Public methods
      User.method_defined?(:track).should == true
      User.method_defined?(:tracking).should == true
      User.method_defined?(:"tracks?").should == true
      User.method_defined?(:untrack).should == true
      User.method_defined?(:block).should == true
      User.method_defined?(:blocked).should == true
      User.method_defined?(:"blocks?").should == true
      User.method_defined?(:unblock).should == true
      User.method_defined?(:join).should == true
      User.method_defined?(:groups).should == true
      User.method_defined?(:"member_of?").should == true
      User.method_defined?(:leave).should == true
      User.method_defined?(:profile_feed).should == true
      User.method_defined?(:feed).should == true
      User.method_defined?(:profile_feed_key).should == true
      User.method_defined?(:feed_key).should == true
      # Private methods
      User.private_method_defined?(:add_tekeya_relation).should == true
      User.private_method_defined?(:delete_tekeya_relation).should == true
      User.private_method_defined?(:tekeya_relations_of).should == true
      User.private_method_defined?(:"tekeya_relation_exists?").should == true
    end

    describe "errors" do
      it "should raise a non entity error when tracking or blocking a non entity" do
        expect { @user.track(nil) }.to raise_error(Tekeya::Errors::TekeyaNonEntity)
        expect { @user.block(nil) }.to raise_error(Tekeya::Errors::TekeyaNonEntity)
      end

      it "should raise a non group error if a non group is given when joining a non group" do
        expect { @user.join(nil) }.to raise_error(Tekeya::Errors::TekeyaNonGroup)
      end

      it "should raise a relation already exists error when tracking, blocking or joining an already tracked, blocked or joined entity/group" do
        @user.track(@user2)
        expect { @user.track(@user2) }.to raise_error(Tekeya::Errors::TekeyaRelationAlreadyExists)
        @user.block(@user2)
        expect { @user.block(@user2) }.to raise_error(Tekeya::Errors::TekeyaRelationAlreadyExists)
        @user.join(@group)
        expect { @user.join(@group) }.to raise_error(Tekeya::Errors::TekeyaRelationAlreadyExists)
      end

      it "should raise a relation non existent error when untracking, unblocking or leaving an untracked, unblocked or unjoined entity/group" do
        expect { @user.untrack(@user2) }.to raise_error(Tekeya::Errors::TekeyaRelationNonExistent)
        expect { @user.unblock(@user2) }.to raise_error(Tekeya::Errors::TekeyaRelationNonExistent)
        expect { @user.leave(@group) }.to raise_error(Tekeya::Errors::TekeyaRelationNonExistent)
      end
    end

    describe "privacy" do
      it "should be able to set default privacy to public" do
        @user.privacy_settings.set_default_to_public
        @privacy = @user.privacy_settings.default_privacy_setting
        @privacy.to_public.should == true
        @privacy.friends_only.should == false
      end



      it "should be able to set default privacy to friends only" do
        @user.privacy_settings.set_default_to_friends_only
        @privacy = @user.privacy_settings.default_privacy_setting
        @privacy.friends_only.should == true
        @privacy.to_public == false
      end

      it "should be able to add a not allowed list" do
        @list = @user.owned_lists.first
        @user.privacy_settings.default_privacy_setting.not_allowed_privacy_lists << @list
        @user.privacy_settings.default_privacy_setting.not_allowed_privacy_lists.include?(@list).should == true
      end  

      it "should be able to set default privacy to many lists" do
        @list = @user.owned_lists.create_list('Elshbab')
        @list2 = @user.owned_lists.create_list('Elgyran')
        @list3 = @user.owned_lists.friends_list
        @user.privacy_settings.set_default_to_custom(allowed_privacy_lists: [@list, @list3], not_allowed_privacy_lists: [@list2])
        @privacy = @user.privacy_settings.default_privacy_setting
        @privacy.allowed_privacy_lists.include?(@list).should == true
        @privacy.not_allowed_privacy_lists.include?(@list2).should == true
      end



      it "should be able to set default privacy to forbid a certain list/lists" do
        @list = @user.owned_lists.create_list('Stalkers')
        @friends = @user.owned_lists.friends_list
        @user.privacy_settings.set_default_to_custom(allowed_privacy_lists: [@friends], not_allowed_privacy_lists: [@list])
        @privacy = @user.privacy_settings.default_privacy_setting
        @privacy.not_allowed_privacy_lists.include?(@list).should == true
      end

      it "should be able to know to whom will its activities will be fanned (friends_only case)" do
        @user2.privacy_settings.set_default_to_friends_only
        @user2.track(@user)
        @user.track(@user2)
        @user4.track(@user2)
        @user2.track(@user4)
        @user5.track(@user2)
        @privacy = @user2.privacy_settings.default_privacy_setting
        fans = @privacy.will_fanout_activities_to
        fans.include?(@user).should == true
        fans.include?(@user4).should == true
        fans.include?(@user5).should == false
      end

      it "should be able to know to whom will its activities will be fanned (public case)" do
        @user2.track(@user)
        @user4.track(@user)
        @user5.track(@user)
        @user.privacy_settings.set_default_to_public
        @fans = @user.privacy_settings.default_privacy_setting.will_fanout_activities_to
        @fans.include?(@user2).should == true
        @fans.include?(@user4).should == true
        @fans.include?(@user5).should == true
      end

      it "should be able to know to whom will its activities will be fanned (unrestricted_only case)" do
        @user2.track(@user)
        @user4.track(@user)
        @user5.track(@user)
        @user.privacy_settings.set_default_to_unrestricted_only
        @user.owned_lists.add_member_to_list(@user5, @user.owned_lists.restricted_list)
        @fans = @user.privacy_settings.default_privacy_setting.will_fanout_activities_to
        @fans.include?(@user2).should == true
        @fans.include?(@user4).should == true
        @fans.include?(@user5).should == false
      end  

      it "should be able to know to whom will its activities will be fanned (custom entities case)" do
        @user2.track(@user)
        @user4.track(@user)
        @user5.track(@user)
        @user.privacy_settings.set_default_to_custom(allowed_entities: [@user2, @user4], not_allowed_entities: [@user5])
        @fans = @user.privacy_settings.default_privacy_setting.will_fanout_activities_to
        @fans.include?(@user2).should == true
        @fans.include?(@user4).should == true
        @fans.include?(@user5).should == false
      end
      it "should be able to know whether an entity can see its activities (public case)" do
        @user.privacy_settings.set_default_to_public
        @settings = @user.privacy_settings
        @settings.default_privacy_setting.can_see_future_activities?(@user2).should == true
      end

      it "should be able to know who can see its activities (unrestricted_only case)" do
        @user.privacy_settings.set_default_to_unrestricted_only
        @settings = @user.privacy_settings
        @user2.track(@user)
        @user.owned_lists.restricted_list.add_member(@user2)
        @settings.default_privacy_setting.can_see_future_activities?(@user2).should == false
        @user.owned_lists.restricted_list.remove_member(@user2)
        @settings.default_privacy_setting.can_see_future_activities?(@user2).should == true
      end

      it "should be able to know who can see its activities (friends_only case)" do
        @user.privacy_settings.set_default_to_friends_only
        @settings = @user.privacy_settings
        @user2.track(@user)
        @user.track(@user2)
        @settings.default_privacy_setting.can_see_future_activities?(@user2).should == true
        @user.owned_lists.friends_list.remove_member(@user2)
        @settings.default_privacy_setting.can_see_future_activities?(@user2).should == false
      end

      it "should be able to know who can see its activities (custom case)" do
        @user2.track(@user)
        @user4.track(@user)
        @user5.track(@user)
        @user.privacy_settings.set_default_to_custom(allowed_entities: [@user2,@user4])
        @settings = @user.privacy_settings
        @settings.default_privacy_setting.can_see_future_activities?(@user2).should == true
        @settings.default_privacy_setting.can_see_future_activities?(@user4).should == true
        @settings.default_privacy_setting.can_see_future_activities?(@user5).should == false
      end

      it "should be able to return to an entity only profile_feed activities which the entity is allowed to see (public case) " do
        @user.privacy_settings.set_default_to_public
        @act =  @user.activities.posted Fabricate(:status)
        @feed = @user.profile_feed_for(@user2)
        @feed.map(&:activity_id).include?(@act.id.to_s).should == true
      end

      it "should be able to return to an entity only profile_feed activities which the entity is allowed to see (friends only case) " do
        @user.privacy_settings.set_default_to_friends_only
        @act =  @user.activities.posted Fabricate(:status)
        @feed = @user.profile_feed_for(@user2)
        @feed.map(&:activity_id).include?(@act.id.to_s).should == false
        @user.track(@user2)
        @user2.track(@user)
        @feed = @user.profile_feed_for(@user2)
        @feed.map(&:activity_id).include?(@act.id.to_s).should == true
      end

      it "should be able to return to an entity only profile_feed activities which the entity is allowed to see (unrestricted_only case) " do
        @user.privacy_settings.set_default_to_unrestricted_only
        @act = @user.activities.posted Fabricate(:status)
        @feed = @user.profile_feed_for(@user2)
        @feed.map(&:activity_id).include?(@act.id.to_s).should == true
        @user.owned_lists.restricted_list.add_member(@user2)
        @feed = @user.profile_feed_for(@user2)
        @feed.map(&:activity_id).include?(@act.id.to_s).should == false
      end

      it "should be able to return to an entity only profile_feed activities which the entity is allowed to see (custom case) " do 
        @friends = @user.owned_lists.friends_list
        @user.track(@user2)
        @user2.track(@user)
        @user.privacy_settings.set_default_to_custom(allowed_privacy_lists: [@friends], not_allowed_entities: [@user2])
        @act = @user.activities.posted Fabricate(:status)
        @feed = @user.profile_feed_for(@user2)
        @feed.map(&:activity_id).include?(@act.id.to_s).should == false
        @user.privacy_settings.set_default_to_custom(allowed_privacy_lists: [@friends])
        @act2 = @user.activities.posted Fabricate(:status)
        @feed = @user.profile_feed_for(@user2)
        @feed.map(&:activity_id).include?(@act2.id.to_s).should == true
      end
    end  

    describe "relations" do

      it "should be able to create a new list as an owner" do
        @list = @user.owned_lists.create_list('Family2')
        owned_lists_ids = @user.owned_lists.map(&:id)
        owned_lists_ids.include?(@list.id).should == true
      end

      it "should not be able to create a list with an existing name" do
        @list = @user.owned_lists.create_list('Family2')
        @list2 = @user.owned_lists.create_list('Family2')
        @user.owned_lists.include?(@list).should == true
        @user.owned_lists.include?(@list2).should == false
      end

      it "should be able to mark a list as deleted" do
        @list =  @user.owned_lists.create_list('Family2')
        @user.owned_lists.mark_as_deleted(@list)
        @list.deleted?.should == true
      end

      it "should be able to add a new member to the list if the new member is a tracker" do
        @list = @user.owned_lists.create_list('Family2')
        @user2.track(@user)
        @user.owned_lists.add_member_to_list(@user2, @list)
        @list.members.include?(@user2).should == true
      end

      it "should be able to know if it's a member in any of the lists owned by a particular entity" do
        @list = @user.owned_lists.create_list('Family2')
        @user2.track(@user)
        @user.owned_lists.add_member_to_list(@user2, @list)
        @user2.lists.any_owned_by?(@user).should == true
        @user2.listings.leave(@list)
        @user2.lists.any_owned_by?(@user).should == false
      end

      it "should be able to retrieve owned lists by a particular entity in which it's a member" do
        @list = @user.owned_lists.create_list('Family2')
        @user2.track(@user)
        @user.owned_lists.add_member_to_list(@user2, @list)
        @user2.lists.owned_by(@user).include?(@list).should == true
      end 

      it "should not be able to add a new member to the list if the new member is not a tracker" do
        @list = @user.owned_lists.create_list('Family2')
        @user.owned_lists.add_member_to_list(@user2, @list)
        @list.members.include?(@user2).should == false
      end 

      it "should be able to leave a list" do
        @list = @user.owned_lists.create_list('Family2')
        @user2.track(@user)
        @user.owned_lists.add_member_to_list(@user2, @list)
        @list.members.include?(@user2).should == true
        @user2.listings.leave(@list)
        @list.members.include?(@user2).should == false
      end

      it "should be able to remove a member from an owned list" do
        @list = @user.owned_lists.create_list('Family2')
        @user2.track(@user)
        @user.owned_lists.add_member_to_list(@user2, @list)
        @list.members.include?(@user2).should == true
        @user.owned_lists.remove_member_from_list(@user2, @list)
        @list.members.include?(@user2).should == false
      end

      it "should add and join respective friends list on tracking an entity which tracks it" do
        @user.track(@user2)
        @user2.track(@user)
        @user.owned_lists.friends_list.has_member?(@user2).should == true
        @user2.owned_lists.friends_list.has_member?(@user).should == true
      end

      it "should remove entity from friends_list after untracking it in case entity is a member in friends_list" do
        @user.track(@user2)
        @user2.track(@user)
        @user.owned_lists.friends_list.has_member?(@user2).should == true
        @user2.owned_lists.friends_list.has_member?(@user).should == true
        @user.untrack(@user2)
        @user.owned_lists.friends_list.has_member?(@user2).should == false
        @user2.owned_lists.friends_list.has_member?(@user).should == false
      end  

      it "should leave lists after untracking owner of lists" do
        @list = @user.owned_lists.create_list('Family2')
        @user2.track(@user)
        @user.owned_lists.add_member_to_list(@user2, @list)
        @list.members.include?(@user2).should == true
        @user2.untrack(@user)
        @list.members.include?(@user2).should == false
      end  

      it "should track another entity" do
        @user.track(@user2).should == true
        @user.tracks?(@user2).should == true
      end

      it "should untrack a tracked entity" do
        @user.track(@user2)
        @user.untrack(@user2).should == true
        @user.tracks?(@user2).should_not == true
      end

      it "should block another entity/group" do
        @user.block(@user2).should == true
        @user.blocks?(@user2).should == true
        @user.block(@group).should == true
        @user.blocks?(@group).should == true
      end

      it "should unblock a blocked entity/group" do
        @user.block(@user2)
        @user.unblock(@user2).should == true
        @user.blocks?(@user2).should_not == true

        @user.block(@group)
        @user.unblock(@group).should == true
        @user.blocks?(@group).should_not == true
      end

      it "should join a group" do
        @user.join(@group).should == true
        @user.member_of?(@group).should == true
      end

      it "should leave a group" do
        @user.join(@group)
        @user.leave(@group).should == true
        @user.member_of?(@group).should_not == true
      end

      describe "retrieval" do
        before :each do
          @user3 = Fabricate(:user)
          @company = Fabricate(:company)

          @user.track(@user2)
          @user.block(@user3)
          @user.join(@group)
          @user2.join(@group)
          @user3.join(@group)
          @company.track(@user2)
        end

        it "should return tracked entities" do
          @user.tracking.include?(@user2).should == true
        end

        it "should return trackers" do
          @user2.trackers.include?(@user).should == true
          @user2.trackers.include?(@company).should == true
        end

        it "should return blocked entities" do
          @user.blocked.include?(@user3).should == true
        end

        it "should return joined groups" do
          @user.groups.include?(@group).should == true
        end

        it "should return group members" do
          @group.members.should == [@user, @user2, @user3]
        end
      end

      describe "blocking entities" do
        it "should remove the tracking relation if it exists" do
          @user.track(@user2)
          @user2.track(@user)
          @user.block(@user2)

          @user.tracks?(@user2).should_not == true
          @user2.tracks?(@user).should_not == true
        end
      end

      describe "groups" do
        it "should track the group automatically when an entity joins" do
          @user.join(@group)
          @user.tracks?(@group).should == true
        end

        it "should untrack the group automatically when an entity leaves" do
          @user.join(@group)
          @user.leave(@group)
          @user.tracks?(@group).should_not == true
        end
      end
    end
  end
end