import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/core/services/voice_service.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_event.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';

class SettingsPage extends StatefulWidget {
  final bool isTab;
  const SettingsPage({super.key, this.isTab = false});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 120.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _buildSectionHeader('DISPLAY'),
          const SizedBox(height: 12),
          BlocBuilder<ContactsBloc, ContactsState>(
            builder: (context, state) {
              final sortOrder = state is ContactsLoaded ? state.sortOrder : ContactSortOrder.firstName;
              final nameFormat = state is ContactsLoaded ? state.nameFormat : ContactNameFormat.firstLast;

              return _buildSettingsContainer([
                _buildSettingItem(
                  icon: Icons.sort_rounded,
                  title: 'Sort by',
                  trailingText: sortOrder == ContactSortOrder.firstName ? 'First name' : 'Last name',
                  onTap: () => _showSortOrderDialog(context, sortOrder),
                ),
                const Divider(height: 1, indent: 64, endIndent: 20),
                _buildSettingItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Name format',
                  trailingText: nameFormat == ContactNameFormat.firstLast ? 'First name first' : 'Last name first',
                  onTap: () => _showNameFormatDialog(context, nameFormat),
                ),
              ]);
            },
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('VOICE ASSISTANT'),
          const SizedBox(height: 16),
          _buildSettingsContainer([
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF33A1E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Color(0xFF33A1E5),
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Enable Voice Assistant',
                  style: TextStyle(
                    color: AppColors.textBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: Switch(
                  value: RepositoryProvider.of<VoiceAssistantService>(context).isEnabled,
                  onChanged: (value) {
                    RepositoryProvider.of<VoiceAssistantService>(context).setEnabled(value);
                    setState(() {}); // Force rebuild to update toggle
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF33A1E5),
                ),
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
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF33A1E5).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 24,
          color: const Color(0xFF33A1E5),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textBlue,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trailingText,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }
  void _showSortOrderDialog(BuildContext context, ContactSortOrder current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort by'),
        content: RadioGroup<ContactSortOrder>(
          groupValue: current,
          onChanged: (val) {
            context.read<ContactsBloc>().add(
              UpdateDisplaySettingsEvent(sortOrder: val),
            );
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              RadioListTile<ContactSortOrder>(
                title: Text('First name'),
                value: ContactSortOrder.firstName,
              ),
              RadioListTile<ContactSortOrder>(
                title: Text('Last name'),
                value: ContactSortOrder.lastName,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNameFormatDialog(BuildContext context, ContactNameFormat current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name format'),
        content: RadioGroup<ContactNameFormat>(
          groupValue: current,
          onChanged: (val) {
            context.read<ContactsBloc>().add(
              UpdateDisplaySettingsEvent(nameFormat: val),
            );
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              RadioListTile<ContactNameFormat>(
                title: Text('First name first'),
                value: ContactNameFormat.firstLast,
              ),
              RadioListTile<ContactNameFormat>(
                title: Text('Last name first'),
                value: ContactNameFormat.lastFirst,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
