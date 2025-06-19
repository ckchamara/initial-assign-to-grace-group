# Initial Assign to Grace Group Plugin

A Discourse plugin that automatically assigns new users to a specific group upon their first login to the forum.

## Overview

This plugin monitors user login events and automatically adds users to a designated "grace period" group during their initial authentication. This is useful for implementing grace periods, onboarding workflows, or temporary permissions for new users.

## Features

- **Automatic Assignment**: Users are automatically added to the specified group on their first login
- **One-time Action**: Assignment only occurs once per user (on first login)
- **Configurable Group**: Target group ID can be configured via site settings
- **Error Handling**: Comprehensive error handling and logging
- **Safe Operation**: Checks for existing group membership to prevent duplicates

## Installation

### For Self-Hosted Discourse

1. Navigate to your Discourse installation directory
2. Clone this plugin into the `plugins` directory:
   ```bash
   cd /var/discourse/plugins
   git clone https://github.com/discourse/initial-assign-to-grace-group.git
   ```
3. Rebuild your Discourse container:
   ```bash
   cd /var/discourse
   ./launcher rebuild app
   ```

### For Development Environment

1. Navigate to your Discourse development directory
2. Clone the plugin:
   ```bash
   cd discourse/plugins
   git clone https://github.com/discourse/initial-assign-to-grace-group.git
   ```
3. Restart your development server

## Configuration

After installation, configure the plugin through your Discourse admin panel:

1. Go to **Admin** → **Settings** → **Plugins**
2. Find the "Initial Assign to Grace Group" section
3. Configure the following settings:

### Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `initial_assign_to_grace_group_enabled` | `true` | Enable/disable the plugin functionality |
| `initial_assign_grace_group_id` | `42` | ID of the target group (grace_period_users) |

### Finding Your Group ID

To find the ID of your target group:

1. Go to **Admin** → **Groups**
2. Click on your target group (e.g., "grace_period_users")
3. The group ID will be visible in the URL: `/admin/groups/42` (where 42 is the ID)

## How It Works

### Detection Logic

The plugin uses the following logic to detect first-time logins:

1. **Event Hook**: Listens for the `user_logged_in` DiscourseEvent
2. **First Login Detection**: Checks if `user.first_seen_at` is `nil` or very recent (within 1 minute)
3. **Group Assignment**: Adds the user to the specified group if they're not already a member

### Technical Implementation

- **Event**: `DiscourseEvent.on(:user_logged_in)`
- **Detection**: Uses `user.first_seen_at` field to identify first-time users
- **Assignment**: Uses `Group#add(user)` method for safe group membership
- **Logging**: Comprehensive logging for monitoring and debugging

## Edge Cases Handled

- **Group Not Found**: Logs warning if target group doesn't exist
- **Duplicate Assignment**: Checks existing membership before adding
- **Error Handling**: Catches and logs any exceptions during processing
- **Plugin Disabled**: Respects the enabled/disabled setting

## Testing

### Manual Testing

1. Create a test user account
2. Ensure the target group exists (ID: 42 or your configured ID)
3. Enable the plugin in settings
4. Have the test user log in for the first time
5. Verify the user appears in the target group's member list

### Verification Steps

1. **Check Logs**: Look for plugin messages in `/var/discourse/shared/standalone/log/rails/production.log`
2. **Group Membership**: Verify user appears in Admin → Groups → [Target Group] → Members
3. **Settings**: Confirm plugin settings are properly configured

### Expected Log Messages

```
[initial-assign-to-grace-group] Successfully added user testuser (ID: 123) to group 'grace_period_users' (ID: 42)
```

## Troubleshooting

### Common Issues

1. **Plugin Not Working**
   - Verify plugin is enabled in settings
   - Check that target group exists
   - Review error logs for specific issues

2. **Users Not Being Added**
   - Confirm group ID is correct
   - Check if users are already group members
   - Verify `first_seen_at` logic is working as expected

3. **Error Messages**
   - `Target group with ID X not found`: Create the group or update the group ID setting
   - `User already in group`: Normal behavior, no action needed

### Debug Information

Enable debug logging to see detailed plugin activity:
- Check Rails logs for `[initial-assign-to-grace-group]` messages
- Monitor group membership changes in Admin → Groups

## Development

### Plugin Structure

```
initial-assign-to-grace-group/
├── plugin.rb                    # Main plugin file
├── config/
│   ├── settings.yml             # Plugin settings
│   └── locales/
│       └── server.en.yml        # Server-side translations
└── README.md                    # This documentation
```

### Customization

To modify the plugin behavior:

1. **Change Detection Logic**: Modify the first-login detection in `plugin.rb`
2. **Add Settings**: Update `config/settings.yml` for new configuration options
3. **Custom Events**: Use the `user_added_to_grace_group` event for additional automation

## Security Considerations

- Plugin only adds users to groups, never removes them
- Respects existing group permissions and visibility settings
- Uses safe Discourse APIs for group management
- Includes comprehensive error handling to prevent failures

## License

MIT License - see LICENSE file for details

## Support

For issues, questions, or contributions:
- Create an issue on the GitHub repository
- Post in the Discourse Meta community
- Review the Discourse plugin development documentation

## Version History

- **1.0.0**: Initial release with basic first-login group assignment functionality
