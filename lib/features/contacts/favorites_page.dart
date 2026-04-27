import 'package:flutter/material.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/features/call/call_screen.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class FavoritesPage extends StatelessWidget {
  final List<Contact> favorites;

  const FavoritesPage({super.key, required this.favorites});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Favorites',
          style: TextStyle(
            color: AppColors.textBlue,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: favorites.isEmpty
            ? const Center(
                child: Text(
                  'No favorites yet',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final contact = favorites[index];
                  return _buildGridItem(context, contact);
                },
              ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, Contact contact) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CallScreen(name: contact.displayName ?? '', imagePath: ''),
          ),
        );
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: const Color(0xFFD4E4FC),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: ClipOval(
                child: contact.photo?.thumbnail != null ? Image.memory(contact.photo!.thumbnail!, fit: BoxFit.cover) : const Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            contact.displayName ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textBlue,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
