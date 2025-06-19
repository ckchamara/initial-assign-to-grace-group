# Installation Guide

## Quick Installation

### For Docker-based Discourse (Recommended)

1. **Add the plugin to your app.yml**:
   ```yaml
   hooks:
     after_code:
       - exec:
           cd: $home/plugins
           cmd:
             - git clone https://github.com/discourse/initial-assign-to-grace-group.git
   ```

2. **Rebuild your container**:
   ```bash
   cd /var/discourse
   ./launcher rebuild app
   ```

### For Development Environment

1. **Clone the plugin**:
   ```bash
   cd /path/to/discourse/plugins
   git clone https://github.com/discourse/initial-assign-to-grace-group.git
   ```

2. **Restart your development server**:
   ```bash
   # Stop the server (Ctrl+C)
   # Then restart
   bin/ember-cli -u
   ```

## Post-Installation Setup

### 1. Create the Grace Period Group

If you don't already have a grace period group:

1. Go to **Admin** → **Groups**
2. Click **New Group**
3. Set the group name to "grace_period_users" (or your preferred name)
4. Configure group settings as needed
5. Note the group ID from the URL (e.g., `/admin/groups/42`)

### 2. Configure Plugin Settings

1. Go to **Admin** → **Settings** → **Plugins**
2. Find "Initial Assign to Grace Group" section
3. Configure:
   - **Enable plugin**: Check the box
   - **Grace group ID**: Enter your group ID (default: 42)

### 3. Test the Installation

1. Create a test user account (or use an existing one)
2. Clear the user's `first_seen_at` field (for testing):
   ```ruby
   # In Rails console
   user = User.find_by(username: 'testuser')
   user.update!(first_seen_at: nil)
   ```
3. Have the user log in
4. Check if they appear in the grace period group

## Verification

### Check Plugin is Loaded

1. Go to **Admin** → **Plugins**
2. Look for "initial-assign-to-grace-group" in the list
3. Ensure it shows as "Enabled"

### Monitor Logs

Watch the logs for plugin activity:

```bash
# For Docker installations
cd /var/discourse
./launcher logs app | grep "initial-assign-to-grace-group"

# For development
tail -f log/development.log | grep "initial-assign-to-grace-group"
```

### Expected Log Messages

Successful assignment:
```
[initial-assign-to-grace-group] Successfully added user testuser (ID: 123) to group 'grace_period_users' (ID: 42)
```

User already in group:
```
[initial-assign-to-grace-group] User testuser (ID: 123) is already in group 'grace_period_users' (ID: 42)
```

## Troubleshooting

### Plugin Not Appearing

- Ensure the plugin directory is in the correct location
- Check file permissions
- Rebuild the container completely
- Check for syntax errors in plugin.rb

### Users Not Being Added

1. **Check plugin is enabled**:
   - Admin → Settings → Plugins → Initial Assign to Grace Group

2. **Verify group exists**:
   - Admin → Groups → Check your target group exists
   - Note the correct group ID

3. **Check logs for errors**:
   - Look for warning/error messages in Rails logs

4. **Test first login detection**:
   ```ruby
   # Rails console
   user = User.find_by(username: 'testuser')
   puts "First seen at: #{user.first_seen_at}"
   puts "Is recent: #{user.first_seen_at.nil? || user.first_seen_at > 2.minutes.ago}"
   ```

### Common Issues

| Issue | Solution |
|-------|----------|
| Group ID not found | Update the group ID setting to match your actual group |
| Plugin not loading | Check syntax errors, rebuild container |
| Users already in group | Normal behavior, plugin prevents duplicates |
| No log messages | Check plugin is enabled and user is actually logging in for first time |

## Advanced Configuration

### Custom Group Detection

To modify which group users are added to, you can:

1. Change the `initial_assign_grace_group_id` setting
2. Or modify the plugin code to use group names instead of IDs

### Multiple Groups

To add users to multiple groups, modify the plugin code:

```ruby
# In plugin.rb, replace the single group logic with:
group_ids = [42, 43, 44] # Your group IDs
group_ids.each do |group_id|
  group = Group.find_by(id: group_id)
  next unless group
  group.add(user) unless group.users.include?(user)
end
```

### Custom First Login Logic

To change how first login is detected, modify the condition in plugin.rb:

```ruby
# Current logic
is_first_login = user.first_seen_at.nil? || (user.first_seen_at > 2.minutes.ago)

# Alternative: Use created_at instead
is_first_login = user.created_at > 1.hour.ago

# Alternative: Use custom user field
is_first_login = user.custom_fields['has_logged_in'].blank?
```

## Uninstallation

To remove the plugin:

1. **Remove from app.yml** (Docker):
   ```yaml
   # Remove or comment out the git clone line
   ```

2. **Remove plugin directory**:
   ```bash
   rm -rf /var/discourse/plugins/initial-assign-to-grace-group
   ```

3. **Rebuild container**:
   ```bash
   cd /var/discourse
   ./launcher rebuild app
   ```

Note: Users already added to groups will remain in those groups after plugin removal.
