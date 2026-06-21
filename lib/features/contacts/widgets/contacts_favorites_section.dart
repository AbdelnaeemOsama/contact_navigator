import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';
import 'package:contact_navigator/features/contacts/favorites_page.dart';

/// Collapsible favorites strip on the contacts tab.
class ContactsFavoritesSection extends StatefulWidget {
  final List<Contact> favorites;
  final ContactNameFormat nameFormat;

  const ContactsFavoritesSection({
    super.key,
    required this.favorites,
    required this.nameFormat,
  });

  @override
  State<ContactsFavoritesSection> createState() => _ContactsFavoritesSectionState();
}

class _ContactsFavoritesSectionState extends State<ContactsFavoritesSection> {
  bool _expanded = false;

  static Color _avatarColor(String name) {
    final hash = name.isNotEmpty ? name.codeUnitAt(0) : 0;
    return AppColors.contactAvatarColors[hash % AppColors.contactAvatarColors.length];
  }

  static String _formattedName(Contact contact, ContactNameFormat format) {
    if (contact.name == null) return contact.displayName ?? '';

    final first = contact.name!.first ?? '';
    final last = contact.name!.last ?? '';

    if (first.isEmpty && last.isEmpty) return contact.displayName ?? '';

    if (format == ContactNameFormat.firstLast) {
      return '$first $last'.trim();
    }
    return '$last $first'.trim();
  }

  static Future<void> _callContact(Contact contact) async {
    if (contact.phones.isEmpty) return;
    await FlutterPhoneDirectCaller.callNumber(contact.phones.first.number);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.favorites.isEmpty) return const SizedBox.shrink();

    if (!_expanded) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => setState(() => _expanded = true),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Favorites',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.favorites.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.expand_more_rounded, color: Colors.grey.shade500),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            const Text(
              'Favorites',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textBlue,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => FavoritesPage(favorites: widget.favorites),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _expanded = false),
              icon: Icon(Icons.expand_less_rounded, color: Colors.grey.shade600),
              tooltip: 'Collapse',
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.favorites.length,
            itemBuilder: (context, fIndex) {
              final c = widget.favorites[fIndex];
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: _FavoriteAvatarTile(
                  contact: c,
                  bgColor: _avatarColor(c.displayName ?? ''),
                  name: _formattedName(c, widget.nameFormat),
                  onTap: () => _callContact(c),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FavoriteAvatarTile extends StatelessWidget {
  final Contact contact;
  final Color bgColor;
  final String name;
  final VoidCallback onTap;

  const _FavoriteAvatarTile({
    required this.contact,
    required this.bgColor,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photo = contact.photo?.thumbnail;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: bgColor.withValues(alpha: 0.3),
            backgroundImage: photo != null ? MemoryImage(photo) : null,
            child: photo == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 75,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
