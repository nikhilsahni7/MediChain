import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medileger/config/router/app_router.dart';
import 'package:medileger/core/services/auth_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // User profile section
        if (_userData != null) ...[
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.primary,
                    child: Icon(
                      Icons.local_hospital,
                      size: 40,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userData!['name'] ?? 'Hospital User',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userData!['email'] ?? '',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_userData!['walletAddress'].substring(0, 6)}...${_userData!['walletAddress'].substring(_userData!['walletAddress'].length - 4)}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () {
                          // TODO: Implement copy to clipboard
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Wallet address copied to clipboard'),
                            ),
                          );
                        },
                        tooltip: 'Copy address',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],

        // General settings section
        _buildSectionHeader(context, 'General'),
        _buildSettingTile(
          title: 'App Theme',
          icon: Icons.brightness_6,
          trailing: DropdownButton<String>(
            value: 'System',
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(
                value: 'Light',
                child: Text('Light'),
              ),
              DropdownMenuItem(
                value: 'Dark',
                child: Text('Dark'),
              ),
              DropdownMenuItem(
                value: 'System',
                child: Text('System'),
              ),
            ],
            onChanged: (value) {
              // TODO: Implement theme switching
            },
          ),
        ),
        _buildSettingTile(
          title: 'Notifications',
          icon: Icons.notifications_outlined,
          trailing: Switch(
            value: true,
            onChanged: (value) {
              // TODO: Implement notification settings
            },
          ),
        ),

        // Account settings section
        _buildSectionHeader(context, 'Account'),
        _buildSettingTile(
          title: 'Update Profile',
          icon: Icons.edit_outlined,
          onTap: () {
            // TODO: Navigate to profile edit screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile editing coming soon'),
              ),
            );
          },
        ),
        _buildSettingTile(
          title: 'Change Password',
          icon: Icons.lock_outline,
          onTap: () {
            // TODO: Navigate to password change screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password change coming soon'),
              ),
            );
          },
        ),

        // Support section
        _buildSectionHeader(context, 'Support'),
        _buildSettingTile(
          title: 'Help & FAQs',
          icon: Icons.help_outline,
          onTap: () {
            // TODO: Navigate to help screen
          },
        ),
        _buildSettingTile(
          title: 'Contact Support',
          icon: Icons.support_agent,
          onTap: () {
            // TODO: Navigate to support screen
          },
        ),
        _buildSettingTile(
          title: 'Privacy Policy',
          icon: Icons.privacy_tip_outlined,
          onTap: () {
            // TODO: Navigate to privacy policy screen
          },
        ),
        _buildSettingTile(
          title: 'Terms of Service',
          icon: Icons.description_outlined,
          onTap: () {
            // TODO: Navigate to terms screen
          },
        ),

        // App info section
        _buildSectionHeader(context, 'About'),
        _buildSettingTile(
          title: 'App Version',
          icon: Icons.info_outline,
          trailing: const Text('1.0.0'),
        ),

        // Logout section
        _buildSectionHeader(context, 'Account Actions'),
        _buildSettingTile(
          title: 'Logout',
          icon: Icons.logout,
          textColor: Colors.red,
          iconColor: Colors.red,
          onTap: () {
            _showLogoutConfirmationDialog();
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color:
            iconColor ?? Theme.of(context).colorScheme.primary.withOpacity(0.8),
      ),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
