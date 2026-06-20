import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_event.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';
import 'package:contact_navigator/features/contacts/add_contact_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:contact_navigator/core/utils/map_utils.dart';

/// Space for [CustomBottomNav] (margin + height) so keypad keys are not under the bar.
double _keypadBottomInset(BuildContext context) {
  final safe = MediaQuery.paddingOf(context).bottom;
  return safe + 95;
}

class _KeypadSuggestion {
  final Contact contact;
  final Phone phone;
  final int score;
  final String digitsOnly;

  _KeypadSuggestion({
    required this.contact,
    required this.phone,
    required this.score,
    required this.digitsOnly,
  });

  /// Prefer raw number (keeps + / spaces) for the dial field; fall back to digits.
  String get dialFieldValue {
    final raw = phone.number.trim();
    return raw.isNotEmpty ? raw : digitsOnly;
  }
}

class KeypadPage extends StatefulWidget {
  final void Function(LatLng location)? onNavigateToMap;
  const KeypadPage({super.key, this.onNavigateToMap});

  @override
  State<KeypadPage> createState() => _KeypadPageState();
}

class _KeypadPageState extends State<KeypadPage> {
  String _dialedNumber = '';
  bool _isCalling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<ContactsBloc>().state;
      if (state is ContactsInitial) {
        context.read<ContactsBloc>().add(const LoadContactsEvent());
      }
    });
  }

  static String _letterToT9(String ch) {
    final c = ch.toLowerCase();
    if ('abc'.contains(c)) return '2';
    if ('def'.contains(c)) return '3';
    if ('ghi'.contains(c)) return '4';
    if ('jkl'.contains(c)) return '5';
    if ('mno'.contains(c)) return '6';
    if ('pqrs'.contains(c)) return '7';
    if ('tuv'.contains(c)) return '8';
    if ('wxyz'.contains(c)) return '9';
    return '';
  }

  static String _nameToT9Digits(String? name) {
    if (name == null || name.isEmpty) return '';
    final b = StringBuffer();
    for (var i = 0; i < name.length; i++) {
      final unit = name.substring(i, i + 1);
      final t9 = _letterToT9(unit);
      if (t9.isNotEmpty) b.write(t9);
    }
    return b.toString();
  }

  static List<_KeypadSuggestion> _suggestionsFor(List<Contact> contacts, String dialed) {
    final query = dialed.replaceAll(RegExp(r'\D'), '');
    if (query.isEmpty) return [];

    final raw = <_KeypadSuggestion>[];
    for (final c in contacts) {
      if (c.phones.isEmpty) continue;
      final t9 = _nameToT9Digits(c.displayName ?? '');
      final nameMatch = t9.contains(query);
      final namePrefix = t9.startsWith(query);

      for (final p in c.phones) {
        final digits = p.number.replaceAll(RegExp(r'\D'), '');
        if (digits.isEmpty) continue;

        var score = 0;
        if (digits.startsWith(query)) {
          score += 1000;
        } else if (digits.contains(query)) {
          score += 500;
        }
        if (namePrefix) {
          score += 300;
        } else if (nameMatch) {
          score += 200;
        }
        if (score == 0) continue;

        raw.add(
          _KeypadSuggestion(
            contact: c,
            phone: p,
            score: score,
            digitsOnly: digits,
          ),
        );
      }
    }

    raw.sort((a, b) => b.score.compareTo(a.score));
    final seen = <String>{};
    final unique = <_KeypadSuggestion>[];
    for (final s in raw) {
      final id = s.contact.id ?? s.contact.displayName ?? '';
      final key = '$id|${s.phone.number}';
      if (seen.add(key)) unique.add(s);
      if (unique.length >= 12) break;
    }
    return unique;
  }

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
    if (targetNumber.replaceAll(RegExp(r'\D'), '').isEmpty && !targetNumber.contains('+')) {
      return;
    }
    if (_isCalling) return;

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
    if (number.length <= 10) {
      return '${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
    }
    return number;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = _keypadBottomInset(context);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildNumberDisplayWithAdd(),
          Flexible(
            child: _buildAutocompleteSuggestions(),
          ),
          const SizedBox(height: 8),
          _buildKeypadGrid(),
          const SizedBox(height: 10),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildNumberDisplayWithAdd() {
    return BlocBuilder<ContactsBloc, ContactsState>(
      builder: (context, state) {
        var exists = false;
        if (state is ContactsLoaded && _dialedNumber.isNotEmpty) {
          final queryDigits = _dialedNumber.replaceAll(RegExp(r'\D'), '');
          exists = state.allContacts.any(
            (c) => c.phones.any((p) => p.number.replaceAll(RegExp(r'\D'), '') == queryDigits),
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
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
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

  Widget _buildAutocompleteSuggestions() {
    if (_dialedNumber.replaceAll(RegExp(r'\D'), '').isEmpty && !_dialedNumber.contains('+')) {
      return const SizedBox(height: 8);
    }

    return BlocBuilder<ContactsBloc, ContactsState>(
      builder: (context, state) {
        if (state is ContactsLoading || state is ContactsInitial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                'Loading contacts…',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          );
        }
        if (state is! ContactsLoaded) {
          return const SizedBox(height: 8);
        }

        final items = _suggestionsFor(state.allContacts, _dialedNumber);
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No matching contacts',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E), // Dark card background like black image
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: Colors.white10,
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final name = item.contact.displayName ?? 'Unknown';
                    
                    return Dismissible(
                      key: Key('keypad_suggestion_${item.contact.id ?? name}_${item.phone.number}_$i'),
                      direction: DismissDirection.horizontal,
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          await _makeCall(item.phone.number);
                        } else if (direction == DismissDirection.endToStart) {
                          final link = item.contact.websites.isNotEmpty ? item.contact.websites.first.url : '';
                          var latLng = MapUtils.parseLocationLink(link);
                          if (latLng == null && item.contact.addresses.isNotEmpty) {
                            latLng = MapUtils.parseLocationLink(item.contact.addresses.first.formatted ?? '');
                          }
                          if (latLng != null) {
                            widget.onNavigateToMap?.call(latLng);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No location saved for this contact')),
                            );
                          }
                        }
                        return false;
                      },
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.green.withValues(alpha: 0.2),
                        child: const Icon(Icons.phone_enabled_rounded, color: Colors.green),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.blue.withValues(alpha: 0.2),
                        child: const Icon(Icons.location_on_rounded, color: Colors.blue),
                      ),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _dialedNumber = item.dialFieldValue);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.account_circle_outlined,
                                color: Colors.white70,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.phone.number,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _makeCall(item.phone.number),
                                child: const Icon(
                                  Icons.phone,
                                  color: Colors.green,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeypadGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 8),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 8),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: 8),
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
          const SizedBox(width: 48),
          const Spacer(),
          Material(
            color: Colors.green,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _isCalling ? null : () => _makeCall(),
              child: SizedBox(
                width: 70,
                height: 70,
                child: _isCalling
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.phone, color: Colors.white, size: 32),
              ),
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
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: labels.map(_buildKey).toList(),
    );
  }

  Widget _buildKey(String label) {
    var subLabel = '';
    switch (label) {
      case '2':
        subLabel = 'A B C';
        break;
      case '3':
        subLabel = 'D E F';
        break;
      case '4':
        subLabel = 'G H I';
        break;
      case '5':
        subLabel = 'J K L';
        break;
      case '6':
        subLabel = 'M N O';
        break;
      case '7':
        subLabel = 'P Q R S';
        break;
      case '8':
        subLabel = 'T U V';
        break;
      case '9':
        subLabel = 'W X Y Z';
        break;
      case '0':
        subLabel = '+';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _onNumberTapped(label),
          onLongPress: label == '0' ? () => _onNumberLongPressed(label) : null,
          child: SizedBox(
            width: 70,
            height: 70,
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
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
