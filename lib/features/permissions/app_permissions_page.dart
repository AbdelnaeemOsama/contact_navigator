import 'package:flutter/material.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/features/permissions/phone_permissions_page.dart';

class AppPermissionsPage extends StatelessWidget {
  const AppPermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const cardColor = Colors.white;

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
                'One last thing! You’ll need to grant the following app permission to enable the features you’ve chosen :',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textBlue,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              // Map card
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/location.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 32),
              // Location icon + label
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/icons/map.png',
                    width: 32,
                    height: 32,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Contact Navigator uses your location to enhance call and contact features with location-based functionality.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textBlue,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogContext) {
                        return Center(
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              decoration: BoxDecoration(
                                color: AppColors.dialogBackground,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 18,
                                    ),
                                    child: Text(
                                      'Allow Contact Navigator to access your location?',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textBlue,
                                      ),
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    color: Colors.black26,
                                  ),
                                  SizedBox(
                                    height: 48,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () {
                                              Navigator.of(dialogContext).pop();
                                            },
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const VerticalDivider(
                                          width: 1,
                                          color: Colors.black26,
                                        ),
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () {
                                              Navigator.of(dialogContext).pop();
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const PhonePermissionsPage(),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'Allow',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primaryBlue,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    elevation: 6,
                    // ignore: deprecated_member_use
                    shadowColor: Colors.black.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: const Text(
                    'Allow Access',
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
}
