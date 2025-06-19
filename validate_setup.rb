#!/usr/bin/env ruby
# frozen_string_literal: true

# Validation script for Initial Assign to Grace Group plugin
# Run this in your Discourse Rails console to verify plugin setup

puts "=== Initial Assign to Grace Group Plugin Validation ==="
puts

# Check if plugin is loaded
plugin_loaded = defined?(InitialAssignToGraceGroup)
puts "✓ Plugin module loaded: #{plugin_loaded ? 'YES' : 'NO'}"

# Check site settings
enabled = SiteSetting.initial_assign_to_grace_group_enabled rescue false
group_id = SiteSetting.initial_assign_grace_group_id rescue nil

puts "✓ Plugin enabled: #{enabled ? 'YES' : 'NO'}"
puts "✓ Configured group ID: #{group_id || 'NOT SET'}"

# Check if target group exists
if group_id
  target_group = Group.find_by(id: group_id)
  if target_group
    puts "✓ Target group found: '#{target_group.name}' (ID: #{target_group.id})"
    puts "  - Members: #{target_group.users.count}"
    puts "  - Visibility: #{target_group.visibility_level_name}"
  else
    puts "✗ Target group NOT FOUND (ID: #{group_id})"
    puts "  Available groups:"
    Group.order(:id).limit(10).each do |group|
      puts "    - #{group.name} (ID: #{group.id})"
    end
  end
end

# Check recent user activity
puts
puts "=== Recent User Activity ==="
recent_users = User.where('created_at > ?', 24.hours.ago).order(created_at: :desc).limit(5)

if recent_users.any?
  puts "Recent users (last 24 hours):"
  recent_users.each do |user|
    first_seen = user.first_seen_at ? user.first_seen_at.strftime('%Y-%m-%d %H:%M:%S') : 'Never'
    created = user.created_at.strftime('%Y-%m-%d %H:%M:%S')
    in_group = target_group ? target_group.users.include?(user) : 'N/A'
    
    puts "  - #{user.username} (ID: #{user.id})"
    puts "    Created: #{created}"
    puts "    First seen: #{first_seen}"
    puts "    In grace group: #{in_group}"
    puts
  end
else
  puts "No users created in the last 24 hours"
end

# Test the first login detection logic
puts "=== First Login Detection Test ==="
test_user = User.order(:id).last
if test_user
  is_first_login = test_user.first_seen_at.nil? || (test_user.first_seen_at > 2.minutes.ago)
  puts "Test user: #{test_user.username}"
  puts "First seen at: #{test_user.first_seen_at || 'nil'}"
  puts "Would be considered first login: #{is_first_login ? 'YES' : 'NO'}"
else
  puts "No users found for testing"
end

puts
puts "=== Recommendations ==="

unless plugin_loaded
  puts "⚠ Plugin not loaded - check installation"
end

unless enabled
  puts "⚠ Plugin disabled - enable in Admin → Settings → Plugins"
end

unless group_id && group_id > 0
  puts "⚠ Invalid group ID - set in Admin → Settings → Plugins"
end

if group_id && !target_group
  puts "⚠ Target group doesn't exist - create group with ID #{group_id} or update setting"
end

if plugin_loaded && enabled && target_group
  puts "✓ Plugin appears to be configured correctly!"
  puts "✓ Test by having a new user log in for the first time"
end

puts
puts "=== Manual Test Commands ==="
puts "# To test with an existing user:"
puts "user = User.find_by(username: 'testuser')"
puts "user.update!(first_seen_at: nil)"
puts "DiscourseEvent.trigger(:user_logged_in, user, nil, nil)"
puts
puts "# To check if user was added to group:"
puts "Group.find(#{group_id || 'GROUP_ID'}).users.include?(user)" if group_id

puts
puts "=== Log Monitoring ==="
puts "# Watch logs for plugin activity:"
puts "tail -f log/production.log | grep 'initial-assign-to-grace-group'"
puts
puts "Validation complete!"
