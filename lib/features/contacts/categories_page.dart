import 'package:flutter/material.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';

class CategoryItem {
  final String title;
  final String subtitle;
  final String iconPath;
  final Color iconBgColor;

  CategoryItem({
    required this.title,
    required this.subtitle,
    required this.iconPath,
    this.iconBgColor = const Color(0xFF33A1E5),
  });
}

class CategoriesPage extends StatefulWidget {
  final bool isTab;
  const CategoriesPage({super.key, this.isTab = true});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final List<CategoryItem> categories = [
    CategoryItem(
      title: 'Work',
      subtitle: '12 contacts',
      iconPath: 'assets/images/Categories/suitcase 1.png',
    ),
    CategoryItem(
      title: 'Home',
      subtitle: '5 contacts',
      iconPath: 'assets/images/Categories/home (1) 1.png',
    ),
    CategoryItem(
      title: 'Event',
      subtitle: '8 contacts',
      iconPath: 'assets/images/Categories/confetti 1.png',
    ),
    CategoryItem(
      title: 'VIP Clints',
      subtitle: '3 contacts',
      iconPath: 'assets/images/Categories/Ellipse 7.png',
    ),
    CategoryItem(
      title: 'Other',
      subtitle: '2 contacts',
      iconPath: 'assets/images/Categories/Ellipse 8.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search contacts ....',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset(
                    'assets/images/Categories/loupe 3.png',
                    width: 24,
                    height: 24,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Categories List
          Expanded(
            child: ListView.separated(
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final category = categories[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Category Icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: category.iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Image.asset(
                            category.iconPath,
                            width: 30,
                            height: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Category Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.title,
                              style: const TextStyle(
                                color: AppColors.textBlue,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category.subtitle,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right Arrow
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Image.asset(
                          'assets/images/Categories/right-arrow (1) 3.png',
                          width: 24,
                          height: 24,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
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
          icon: const Icon(Icons.arrow_back, color: AppColors.textBlue, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Categories',
          style: TextStyle(
            color: AppColors.textBlue,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.textBlue, size: 32),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: content,
    );
  }
}
