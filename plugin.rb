# frozen_string_literal: true

# name: initial-assign-to-grace-group
# about: Automatically assigns new users to a specific group upon their first login
# meta_topic_id: TODO
# version: 1.0.0
# authors: Discourse Community
# url: https://github.com/discourse/initial-assign-to-grace-group
# required_version: 2.7.0

enabled_site_setting :initial_assign_to_grace_group_enabled

module ::InitialAssignToGraceGroup
  PLUGIN_NAME = "initial-assign-to-grace-group"
end

after_initialize do
  # Hook into the user_logged_in event to detect when users log in
  DiscourseEvent.on(:user_logged_in) do |user, request, auth_result|
    next unless SiteSetting.initial_assign_to_grace_group_enabled
    next unless user&.persisted? # Ensure user is valid and saved

    begin
      # Check if this is the user's first login by examining first_seen_at
      # first_seen_at is set when a user first visits the site after account creation
      # We use a 2-minute window to account for potential timing issues
      is_first_login = user.first_seen_at.nil? || (user.first_seen_at > 2.minutes.ago)

      if is_first_login
        target_group_id = SiteSetting.initial_assign_grace_group_id

        # Validate group ID is positive
        if target_group_id <= 0
          Rails.logger.warn("[#{InitialAssignToGraceGroup::PLUGIN_NAME}] Invalid group ID: #{target_group_id}")
          next
        end

        # Find the target group
        target_group = Group.find_by(id: target_group_id)

        if target_group.nil?
          Rails.logger.warn("[#{InitialAssignToGraceGroup::PLUGIN_NAME}] Target group with ID #{target_group_id} not found")
          next
        end

        # Check if user is already in the group to avoid duplicate assignments
        unless target_group.users.include?(user)
          # Add user to the group using the safe add method
          if target_group.add(user)
            Rails.logger.info("[#{InitialAssignToGraceGroup::PLUGIN_NAME}] Successfully added user #{user.username} (ID: #{user.id}) to group '#{target_group.name}' (ID: #{target_group.id})")

            # Trigger a custom event for other plugins to hook into
            DiscourseEvent.trigger(:user_added_to_grace_group, user, target_group)
          else
            Rails.logger.error("[#{InitialAssignToGraceGroup::PLUGIN_NAME}] Failed to add user #{user.username} (ID: #{user.id}) to group '#{target_group.name}' (ID: #{target_group.id})")
          end
        else
          Rails.logger.debug("[#{InitialAssignToGraceGroup::PLUGIN_NAME}] User #{user.username} (ID: #{user.id}) is already in group '#{target_group.name}' (ID: #{target_group.id})")
        end
      else
        Rails.logger.debug("[#{InitialAssignToGraceGroup::PLUGIN_NAME}] User #{user.username} (ID: #{user.id}) is not a first-time login (first_seen_at: #{user.first_seen_at})")
      end
    rescue => e
      Rails.logger.error("[#{InitialAssignToGraceGroup::PLUGIN_NAME}] Error processing user #{user&.username || 'unknown'} (ID: #{user&.id || 'unknown'}): #{e.message}")
      Rails.logger.error("[#{InitialAssignToGraceGroup::PLUGIN_NAME}] Backtrace: #{e.backtrace.join("\n")}")
    end
  end

  # Also hook into user_first_logged_in if available (more reliable for first login detection)
  if DiscourseEvent.respond_to?(:user_first_logged_in)
    DiscourseEvent.on(:user_first_logged_in) do |user|
      next unless SiteSetting.initial_assign_to_grace_group_enabled
      next unless user&.persisted?

      begin
        target_group_id = SiteSetting.initial_assign_grace_group_id
        target_group = Group.find_by(id: target_group_id)

        if target_group && !target_group.users.include?(user)
          if target_group.add(user)
            Rails.logger.info("[#{InitialAssignToGraceGroup::PLUGIN_NAME}] Added user #{user.username} to grace group via user_first_logged_in event")
            DiscourseEvent.trigger(:user_added_to_grace_group, user, target_group)
          end
        end
      rescue => e
        Rails.logger.error("[#{InitialAssignToGraceGroup::PLUGIN_NAME}] Error in user_first_logged_in handler: #{e.message}")
      end
    end
  end
end
