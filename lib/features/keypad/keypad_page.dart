import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';
import 'package:contact_navigator/features/contacts/add_contact_page.dart';

class KeypadPage extends StatefulWidget {
  const KeypadPage({super.key});

  @override
  State<KeypadPage> createState() => _KeypadPageState();
}

class _KeypadPageState extends State<KeypadPage> {
  String _dialedNumber = '';
  bool _isCalling = false;

  void _onNumberTapped(String number) {
    HapticFeedback.lightImpact();
    setState(() {
      _dialedNumber += number;
    });
  }

  void _onNumberLongPressed(String number) {
    if (number == '0') {
      HapticFeedback.mediumImpact();
      setState(() {
        _dialedNumber += '+';
      });
    }
  }

  void _onDelete() {
    if (_dialedNumber.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _dialedNumber = _dialedNumber.substring(0, _dialedNumber.length - 1);
      });
    }
  }

  void _onDeleteLongPressed() {
    HapticFeedback.heavyImpact();
    setState(() {
      _dialedNumber = '';
    });
  }

  Future<void> _makeCall([String? number]) async {
    final targetNumber = number ?? _dialedNumber;
    if (targetNumber.isEmpty || _isCalling) return;

    HapticFeedback.mediumImpact();
    setState(() => _isCalling = true);

    try {
      await FlutterPhoneDirectCaller.callNumber(targetNumber);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to start the phone call.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCalling = false);
    }
  }

  String _formatNumber(String number) {
    if (number.length <= 3) return number;
    if (number.length <= 6) return '${number.substring(0, 3)} ${number.substring(3)}';
    if (number.length <= 10) return '${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
    return number;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Number Display with Add Button
          _buildNumberDisplayWithAdd(),
          
          // Match Display (Pill style)
          _buildMatchDisplay(),
    
          const SizedBox(height: 20),
    
          // Keypad Grid
          _buildKeypadGrid(),
    
          const SizedBox(height: 20),
    
          // Action Buttons
          _buildActionButtons(),
          
          const SizedBox(height: 100), // Balanced space for the new pill nav
        ],
      ),
    );
  }

  Widget _buildNumberDisplayWithAdd() {
    return BlocBuilder<ContactsBloc, ContactsState>(
      builder: (context, state) {
        bool exists = false;
        if (state is ContactsLoaded && _dialedNumber.isNotEmpty) {
          final queryDigits = _dialedNumber.replaceAll(RegExp(r'\D'), '');
          exists = state.allContacts.any((c) => 
            c.phones.any((p) => p.number.replaceAll(RegExp(r'\D'), '') == queryDigits)
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  _formatNumber(_dialedNumber),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textBlue,
                  ),
                ),
              ),
              if (_dialedNumber.isNotEmpty && !exists)
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddContactPage(initialPhone: _dialedNumber),
                    ),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 24),
                  color: AppColors.primaryBlue,
                )
              else
                const SizedBox(width: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatchDisplay() {
    if (_dialedNumber.isEmpty) return const SizedBox(height: 40);
    
    return BlocBuilder<ContactsBloc, ContactsState>(
      builder: (context, state) {
        if (state is ContactsLoaded) {
          final query = _dialedNumber.replaceAll(RegExp(r'\D'), '');
          final match = state.allContacts.where((c) {
            final phones = c.phones.map((p) => p.number.replaceAll(RegExp(r'\D'), ''));
            return phones.any((p) => p.contains(query));
          }).firstOrNull;

          if (match == null) return const SizedBox(height: 40);

          return Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_pin_circle_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      match.displayName ?? 'Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    match.phones.first.number,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox(height: 40);
      },
    );
  }

  Widget _buildKeypadGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: 12),
          _buildRow(['*', '0', '#']),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 48), // Spacer to match backspace width for centering
          const Spacer(),
          GestureDetector(
            onTap: () => _makeCall(),
            child: Container(
              width: 75,
              height: 75,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: _isCalling
                  ? const Padding(
                      padding: EdgeInsets.all(22),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.phone, color: Colors.white, size: 36),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 48,
            child: _dialedNumber.isNotEmpty
                ? IconButton(
                    onPressed: _onDelete,
                    onLongPress: _onDeleteLongPressed,
                    icon: const Icon(Icons.backspace_rounded, size: 28),
                    color: Colors.grey,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> labels) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels.map((label) => _buildKey(label)).toList(),
    );
  }

  Widget _buildKey(String label) {
    String subLabel = '';
    switch (label) {
      case '2': subLabel = 'A B C'; break;
      case '3': subLabel = 'D E F'; break;
      case '4': subLabel = 'G H I'; break;
      case '5': subLabel = 'J K L'; break;
      case '6': subLabel = 'M N O'; break;
      case '7': subLabel = 'P Q R S'; break;
      case '8': subLabel = 'T U V'; break;
      case '9': subLabel = 'W X Y Z'; break;
      case '0': subLabel = '+'; break;
    }
    return GestureDetector(
      onTap: () => _onNumberTapped(label),
      onLongPress: () => _onNumberLongPressed(label),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w400,
                color: AppColors.textBlue,
              ),
            ),
            if (subLabel.isNotEmpty)
              Text(
                subLabel,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textBlue,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
