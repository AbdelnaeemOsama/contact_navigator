import 'package:flutter/material.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/features/call/call_screen.dart';

class KeypadPage extends StatefulWidget {
  const KeypadPage({super.key});

  @override
  State<KeypadPage> createState() => _KeypadPageState();
}

class _KeypadPageState extends State<KeypadPage> {
  String _dialedNumber = '';

  void _onNumberTapped(String number) {
    setState(() {
      _dialedNumber += number;
    });
  }

  void _onDelete() {
    if (_dialedNumber.isNotEmpty) {
      setState(() {
        _dialedNumber = _dialedNumber.substring(0, _dialedNumber.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        // Display Area
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SizedBox(
            height: 80,
            child: Center(
              child: Text(
                _dialedNumber,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlue,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        const Spacer(),
        // Keypad Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            children: [
              _buildRow(['1', '2', '3']),
              const SizedBox(height: 20),
              _buildRow(['4', '5', '6']),
              const SizedBox(height: 20),
              _buildRow(['7', '8', '9']),
              const SizedBox(height: 20),
              _buildRow(['*', '0', '#']),
            ],
          ),
        ),
        const Spacer(),
        // Action Buttons
        Padding(
          padding: const EdgeInsets.only(bottom: 40.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 60), // Placeholder to center the call button
              // Call Button
              GestureDetector(
                onTap: () {
                  if (_dialedNumber.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CallScreen(
                          name: _dialedNumber,
                          imagePath: 'assets/images/icons_contact_page/boy 1.png',
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone, color: Colors.white, size: 35),
                ),
              ),
              const SizedBox(width: 20),
              // Backspace Button
              IconButton(
                onPressed: _onDelete,
                icon: const Icon(Icons.backspace_outlined,
                    color: AppColors.textBlue, size: 30),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(List<String> labels) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels.map((label) => _buildKey(label)).toList(),
    );
  }

  Widget _buildKey(String label) {
    return GestureDetector(
      onTap: () => _onNumberTapped(label),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textBlue,
            ),
          ),
        ),
      ),
    );
  }
}
