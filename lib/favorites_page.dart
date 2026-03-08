import 'package:flutter/material.dart';
import 'package:contact_navigator/app_theme.dart';
import 'package:contact_navigator/contacts_page.dart';
import 'package:contact_navigator/call_screen.dart';

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
                CallScreen(name: contact.name, imagePath: contact.imagePath),
          ),
        );
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: contact.bgColor,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: ClipOval(
                child: Image.asset(contact.imagePath, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            contact.name,
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
