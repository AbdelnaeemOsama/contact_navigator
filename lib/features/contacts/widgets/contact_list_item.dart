import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/core/utils/text_utils.dart';
import 'package:contact_navigator/core/utils/map_utils.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_event.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';
import 'package:contact_navigator/features/contacts/add_contact_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:typed_data';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:latlong2/latlong.dart';


class ContactListItem extends StatelessWidget {
  final int index;
  final Contact contact;
  final Color bgColor;
  final ContactNameFormat nameFormat;
  final bool isFavorite;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onRemoveFromGroup;
  final void Function(LatLng location)? onNavigateToMap;

  const ContactListItem({
    super.key,
    required this.index,
    required this.contact,
    required this.bgColor,
    required this.nameFormat,
    required this.isFavorite,
    required this.isExpanded,
    required this.onTap,
    this.onDelete,
    this.onRemoveFromGroup,
    this.onNavigateToMap,
  });

  @override
  Widget build(BuildContext context) {
    final String name = _getFormattedName(contact, nameFormat);
    final String phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
    final Uint8List? photo = contact.photo?.thumbnail;

    return Dismissible(
      key: Key('contact_${contact.id ?? index}_$index'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _makeCall(context, phone);
        } else if (direction == DismissDirection.endToStart) {
          final validLocations = _getValidLocations();
          if (validLocations.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No location saved for this contact')),
            );
          } else if (validLocations.length > 1) {
            _showLocationPicker(context, validLocations);
          } else {
            onNavigateToMap?.call(validLocations.first.value);
          }
        }
        return false;
      },
      background: _buildDismissBackground(
        alignment: Alignment.centerLeft,
        icon: Icons.phone_enabled_rounded,
      ),
      secondaryBackground: _buildDismissBackground(
        alignment: Alignment.centerRight,
        icon: Icons.location_on_rounded,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 16),
          padding: isExpanded ? const EdgeInsets.all(16) : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: isExpanded ? const Color(0xFFB9BFD6) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: isExpanded ? 28 : 30,
                    backgroundColor: bgColor.withValues(alpha: 0.3),
                    backgroundImage: photo != null ? MemoryImage(photo) : null,
                    child: photo == null
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: isExpanded ? 20 : 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBlue,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Directionality(
                      textDirection: TextUtils.getTextDirection(name),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: AppColors.textBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isExpanded)
                            const Text(
                              'Address',
                              style: TextStyle(
                                color: AppColors.textBlue,
                                fontSize: 14,
                              ),
                            )
                          else ...[
                            const SizedBox(height: 4),
                            Text(
                              phone,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded)
                    Row(
                      children: [
                        _FavoriteButton(contact: contact, isFavorite: isFavorite),
                        Text(
                          phone,
                          style: const TextStyle(
                            color: AppColors.textBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  else
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey,
                      size: 24,
                    ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionIcon(
                      '',
                      icon: Icons.call_rounded,
                      onTap: () {
                        if (contact.phones.length > 1) {
                          _showPhonePicker(context);
                        } else {
                          _makeCall(context, phone);
                        }
                      },
                    ),
                    _buildActionIcon(
                      '',
                      icon: Icons.edit_note,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddContactPage(contactToEdit: contact),
                          ),
                        );
                        if (result == true) {
                          // Parent should handle reload if needed
                        }
                      },
                    ),
                    _buildActionIcon(
                      '',
                      icon: Icons.delete_outline,
                      onTap: () {
                        _showDeleteDialog(context);
                      },
                    ),
                    if (onRemoveFromGroup != null)
                      _buildActionIcon(
                        '',
                        icon: Icons.group_remove_outlined,
                        onTap: () {
                          _showRemoveFromGroupDialog(context);
                        },
                      ),
                    _buildActionIcon(
                      '',
                      icon: Icons.map_rounded,
                      onTap: () {
                        final validLocations = _getValidLocations();

                        if (validLocations.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No location saved for this contact')),
                          );
                        } else if (validLocations.length > 1) {
                          _showLocationPicker(context, validLocations);
                        } else {
                          onNavigateToMap?.call(validLocations.first.value);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDismissBackground({required Alignment alignment, required IconData icon}) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 32,
        color: const Color(0xFF33A1E5),
      ),
    );
  }

  Widget _buildActionIcon(String path, {IconData? icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: icon != null
            ? Icon(icon, size: 32, color: const Color(0xFF33A1E5))
            : Image.asset(
                path,
                width: 32,
                height: 32,
                color: const Color(0xFF33A1E5),
              ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final displayName = contact.displayName ?? 'this contact';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete $displayName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (contact.id != null) {
                context.read<ContactsBloc>().add(DeleteContactEvent(contact.id!));
              }
              Navigator.pop(dialogContext);
              if (onDelete != null) onDelete!();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _makeCall(BuildContext context, String phone) async {
    if (phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This contact does not have a phone number.')),
      );
      return;
    }

    try {
      await FlutterPhoneDirectCaller.callNumber(phone);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to start the phone call.')),
        );
      }
    }
  }

  void _showPhonePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose Phone Number', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...contact.phones.map((p) => ListTile(
              leading: const Icon(Icons.phone, color: AppColors.primaryBlue),
              title: Text(p.number),
              subtitle: Text(p.label.label == PhoneLabel.custom ? (p.label.customLabel ?? '') : p.label.label.name),
              onTap: () {
                Navigator.pop(context);
                _makeCall(context, p.number);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker(BuildContext context, List<MapEntry<String, LatLng>> validLocations) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...validLocations.map((locEntry) => ListTile(
                leading: const Icon(Icons.location_on, color: Colors.red),
                title: Text(locEntry.key, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.pop(context);
                  onNavigateToMap?.call(locEntry.value);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  void _showRemoveFromGroupDialog(BuildContext context) {
    final displayName = contact.displayName ?? 'this contact';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove from Category'),
        content: Text('Are you sure you want to remove $displayName from this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (onRemoveFromGroup != null) onRemoveFromGroup!();
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, LatLng>> _getValidLocations() {
    final List<MapEntry<String, LatLng>> validLocations = [];
    
    // 1. Parse websites
    for (int i = 0; i < contact.websites.length; i++) {
      final loc = MapUtils.parseLocationLink(contact.websites[i].url);
      if (loc != null) {
         String label = 'Location ${validLocations.length + 1}';
         if (i < contact.addresses.length && contact.addresses[i].formatted?.isNotEmpty == true) {
           label = contact.addresses[i].formatted!;
         }
         validLocations.add(MapEntry(label, loc));
      }
    }

    // 2. Parse addresses
    for (final addr in contact.addresses) {
       final loc = MapUtils.parseLocationLink(addr.formatted ?? '');
       if (loc != null) {
         // Prevent exact duplicates
         if (!validLocations.any((e) => e.value.latitude == loc.latitude && e.value.longitude == loc.longitude)) {
           validLocations.add(MapEntry(addr.formatted ?? 'Address Location', loc));
         }
       }
    }
    return validLocations;
  }

  String _getFormattedName(Contact contact, ContactNameFormat format) {
    final first = contact.name?.first ?? '';
    final last = contact.name?.last ?? '';

    if (first.isEmpty && last.isEmpty) return contact.displayName ?? 'Unknown';

    if (format == ContactNameFormat.firstLast) {
      return '$first $last'.trim();
    } else {
      return '$last $first'.trim();
    }
  }
}

class _FavoriteButton extends StatelessWidget {
  final Contact contact;
  final bool isFavorite;

  const _FavoriteButton({
    required this.contact,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        context.read<ContactsBloc>().add(ToggleFavoriteEvent(contact));
      },
      icon: Icon(
        isFavorite ? Icons.star : Icons.star_border,
        color: isFavorite ? Colors.amber : Colors.grey,
        size: 24,
      ),
    );
  }
}
