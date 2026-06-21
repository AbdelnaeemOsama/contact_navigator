import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';
import 'package:contact_navigator/features/contacts/favorites_page.dart';
import 'package:contact_navigator/features/contacts/widgets/contact_list_item.dart';
import 'package:latlong2/latlong.dart';

/// Collapsible favorites section using the same [ContactListItem] as the main list.
class ContactsFavoritesSection extends StatefulWidget {
  final List<Contact> favorites;
  final ContactNameFormat nameFormat;
  final Set<String> favoriteIds;
  final String? expandedContactId;
  final void Function(Contact contact) onContactTap;
  final void Function(LatLng location)? onNavigateToMap;
  final Color Function(String name) contactColor;

  const ContactsFavoritesSection({
    super.key,
    required this.favorites,
    required this.nameFormat,
    required this.favoriteIds,
    required this.expandedContactId,
    required this.onContactTap,
    required this.contactColor,
    this.onNavigateToMap,
  });

  @override
  State<ContactsFavoritesSection> createState() => _ContactsFavoritesSectionState();
}

class _ContactsFavoritesSectionState extends State<ContactsFavoritesSection> {
  bool _sectionExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.favorites.isEmpty) return const SizedBox.shrink();

    if (!_sectionExpanded) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => setState(() => _sectionExpanded = true),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'Favorites',
                    style: TextStyle(
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
                  builder: (context) => FavoritesPage(
                    favorites: widget.favorites,
                    onNavigateToMap: widget.onNavigateToMap,
                  ),
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
              onPressed: () => setState(() => _sectionExpanded = false),
              icon: Icon(Icons.expand_less_rounded, color: Colors.grey.shade600),
              tooltip: 'Collapse',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(widget.favorites.length, (index) {
          final contact = widget.favorites[index];
          final contactId = contact.id;
          return ContactListItem(
            key: ValueKey('favorite_${contactId ?? index}'),
            index: index,
            contact: contact,
            bgColor: widget.contactColor(contact.displayName ?? ''),
            nameFormat: widget.nameFormat,
            isFavorite: widget.favoriteIds.contains(contactId),
            isExpanded: widget.expandedContactId != null &&
                widget.expandedContactId == contactId,
            onTap: () => widget.onContactTap(contact),
            onNavigateToMap: widget.onNavigateToMap,
          );
        }),
      ],
    );
  }
}
