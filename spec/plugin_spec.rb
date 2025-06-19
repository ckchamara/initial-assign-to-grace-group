# frozen_string_literal: true

require 'rails_helper'

describe 'Initial Assign to Grace Group Plugin' do
  let(:user) { Fabricate(:user) }
  let(:grace_group) { Fabricate(:group, id: 42, name: 'grace_period_users') }
  
  before do
    SiteSetting.initial_assign_to_grace_group_enabled = true
    SiteSetting.initial_assign_grace_group_id = grace_group.id
  end

  describe 'user_logged_in event' do
    context 'when user logs in for the first time' do
      it 'adds user to grace group' do
        # Simulate first login by setting first_seen_at to nil
        user.update!(first_seen_at: nil)
        
        expect {
          DiscourseEvent.trigger(:user_logged_in, user, nil, nil)
        }.to change { grace_group.users.count }.by(1)
        
        expect(grace_group.users).to include(user)
      end
    end

    context 'when user has already logged in before' do
      it 'does not add user to grace group' do
        # Simulate existing user with first_seen_at set
        user.update!(first_seen_at: 1.day.ago)
        
        expect {
          DiscourseEvent.trigger(:user_logged_in, user, nil, nil)
        }.not_to change { grace_group.users.count }
      end
    end

    context 'when user is already in grace group' do
      it 'does not add user again' do
        user.update!(first_seen_at: nil)
        grace_group.add(user)
        
        expect {
          DiscourseEvent.trigger(:user_logged_in, user, nil, nil)
        }.not_to change { grace_group.users.count }
      end
    end

    context 'when plugin is disabled' do
      it 'does not add user to grace group' do
        SiteSetting.initial_assign_to_grace_group_enabled = false
        user.update!(first_seen_at: nil)
        
        expect {
          DiscourseEvent.trigger(:user_logged_in, user, nil, nil)
        }.not_to change { grace_group.users.count }
      end
    end

    context 'when target group does not exist' do
      it 'logs warning and does not raise error' do
        SiteSetting.initial_assign_grace_group_id = 999
        user.update!(first_seen_at: nil)
        
        expect(Rails.logger).to receive(:warn).with(/Target group with ID 999 not found/)
        
        expect {
          DiscourseEvent.trigger(:user_logged_in, user, nil, nil)
        }.not_to raise_error
      end
    end
  end
end
