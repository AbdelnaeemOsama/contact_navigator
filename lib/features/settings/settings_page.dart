import 'package:flutter/material.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  final bool isTab;
  const SettingsPage({super.key, this.isTab = false});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _voiceAssistantEnabled = true;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _buildSectionHeader('Display'),
          const SizedBox(height: 16),
          _buildSettingsContainer([
            _buildSettingItem(
              iconPath: 'assets/images/icons_setting/sort 1.png',
              title: 'Sort by',
              trailingText: 'First name',
              onTap: () {},
            ),
            const Divider(height: 1, indent: 60),
            _buildSettingItem(
              iconPath: 'assets/images/icons_setting/profile 2.png',
              title: 'Name formt',
              trailingText: 'First name first',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 48),
          _buildSectionHeader('VOICE ASSISTANT'),
          const SizedBox(height: 16),
          _buildSettingsContainer([
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: const Icon(
                Icons.mic,
                color: Color(0xFF33A1E5),
                size: 32,
              ),
              title: const Text(
                'Enable Voice Assistant',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Switch(
                value: _voiceAssistantEnabled,
                onChanged: (value) {
                  setState(() {
                    _voiceAssistantEnabled = value;
                  });
                },
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF33A1E5),
              ),
            ),
          ]),
        ],
      ),
    );

    if (widget.isTab) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textBlue,
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textBlue,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: content,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem({
    required String iconPath,
    required String title,
    required String trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Image.asset(
        iconPath,
        width: 32,
        height: 32,
        color: const Color(0xFF33A1E5),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trailingText,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
        ],
      ),
    );
  }
}
