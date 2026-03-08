import 'package:flutter/material.dart';
import 'package:contact_navigator/app_theme.dart';
import 'package:contact_navigator/contacts_page.dart';

class AllPermissionsPage extends StatefulWidget {
  const AllPermissionsPage({super.key});

  @override
  State<AllPermissionsPage> createState() => _AllPermissionsPageState();
}

class _AllPermissionsPageState extends State<AllPermissionsPage> {
  // Switch states
  bool phoneGranted = true;
  bool contactsGranted = true;
  bool locationGranted = true;

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF33A1E5); // Matches the light blue in the design

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                'App Permissions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBlue,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'One last thing! You’ll need to grant the following app permission to enable the features you’ve chosen:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textBlue,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Phone Card
              _buildPermissionCard(
                iconPath: 'assets/images/icons/calling.png',
                title: 'Phone',
                description:
                    'Contact Navigator requires phone access to enable making and managing calls within the app.',
                cardColor: cardColor,
                value: phoneGranted,
                onChanged: (val) {
                  setState(() {
                    phoneGranted = val;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Contacts Card
              _buildPermissionCard(
                iconPath: 'assets/images/icons/contact.png',
                title: 'Contacts',
                description:
                    'Contact Navigator requires access to your contacts to display, manage, and organize contact information.',
                cardColor: cardColor,
                value: contactsGranted,
                onChanged: (val) {
                  setState(() {
                    contactsGranted = val;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Location Card
              _buildPermissionCard(
                iconPath: 'assets/images/icons/location.png',
                title: 'Location',
                description:
                    'Contact Navigator uses your location to enhance call and contact features with location-based functionality.',
                cardColor: cardColor,
                value: locationGranted,
                onChanged: (val) {
                  setState(() {
                    locationGranted = val;
                  });
                },
              ),

              const Spacer(),

              // Next Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContactsPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cardColor,
                    elevation: 6,
                    // ignore: deprecated_member_use
                    shadowColor: Colors.black.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String iconPath,
    required String title,
    required String description,
    required Color cardColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                iconPath,
                width: 24,
                height: 24,
                color: Colors.white, // Ensure icon is white if not already
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => onChanged(!value),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: value ? 1.0 : 0.6,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.rotationY(value ? 0 : 3.14159),
                    transformAlignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/icons/toggle.png',
                      height: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
