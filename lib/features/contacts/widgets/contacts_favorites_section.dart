import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';
import 'package:contact_navigator/features/contacts/favorites_page.dart';

/// Horizontal "Favorites" strip on the contacts tab (header + avatars + "View all").
class ContactsFavoritesSection extends StatelessWidget {
  final List<Contact> favorites;
  final ContactNameFormat nameFormat;

  const ContactsFavoritesSection({
    super.key,
    required this.favorites,
    required this.nameFormat,
  });

  static Color _avatarColor(String name) {
    const colors = [
      Color(0xFFD4E4FC),
      Color(0xFFC2E8FF),
      Color(0xFFFF7B93),
      Color(0xFFE5E7EB),
    ];
    return colors[name.hashCode % colors.length];
  }

  static String _formattedName(Contact contact, ContactNameFormat format) {
    if (contact.name == null) return contact.displayName ?? '';

    final first = contact.name!.first;
    final last = contact.name!.last;

    if (format == ContactNameFormat.firstLast) {
      return '$first $last'.replaceAll('null', '').trim();
    }
    return '$last $first'.replaceAll('null', '').trim();
  }

  static Future<void> _callContact(Contact contact) async {
    if (contact.phones.isEmpty) return;
    await FlutterPhoneDirectCaller.callNumber(contact.phones.first.number);
  }

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Favorites',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textBlue,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => FavoritesPage(favorites: favorites),
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
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length,
            itemBuilder: (context, fIndex) {
              final c = favorites[fIndex];
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: _FavoriteAvatarTile(
                  contact: c,
                  bgColor: _avatarColor(c.displayName ?? ''),
                  name: _formattedName(c, nameFormat),
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
