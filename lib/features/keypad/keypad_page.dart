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
    if (number.isEmpty) return '';

    final hasPlus = number.startsWith('+');
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return number;

    final buffer = StringBuffer();
    if (hasPlus) buffer.write('+');

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = _keypadBottomInset(context);
    final screenWidth = MediaQuery.sizeOf(context).width;

    final hasQuery = _dialedNumber.replaceAll(RegExp(r'\D'), '').isNotEmpty ||
        _dialedNumber.contains('+');

    const sidePad = 24.0;
    const colGap = 18.0;
    const numRows = 5; // 4 digit rows + bottom action row

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Fixed heights
          const topPad = 8.0;
          const numDisplayH = 52.0;
          const numDisplayGap = 4.0;
          final suggestionsH = hasQuery ? 110.0 : 0.0;
          const suggToKeyGap = 8.0;
          const bottomPad = 4.0;

          // All space that goes to the keypad
          final chrome = topPad + numDisplayH + numDisplayGap +
              suggestionsH + suggToKeyGap + bottomPad;
          final keypadAvail =
              (constraints.maxHeight - chrome).clamp(0.0, double.infinity);

          // Max key width from screen width
          final maxKeyFromWidth =
              ((screenWidth - sidePad * 2 - colGap * 2) / 3).clamp(52.0, 90.0);

          // Distribute keypadAvail across 5 rows and 4 gaps
          // Start with a modest gap and solve for keySize
          const minGap = 6.0;
          const maxGap = 22.0;
          final rawKey = (keypadAvail - (numRows - 1) * minGap) / numRows;
          final keySize = rawKey.clamp(52.0, maxKeyFromWidth);
          final rowGap =
              ((keypadAvail - numRows * keySize) / (numRows - 1)).clamp(
                  minGap, maxGap);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: topPad),
              SizedBox(height: numDisplayH, child: _buildNumberDisplayWithAdd()),
              const SizedBox(height: numDisplayGap),
              if (hasQuery)
                SizedBox(height: suggestionsH, child: _buildAutocompleteSuggestions()),
              const SizedBox(height: suggToKeyGap),
              _buildIosKeypad(keySize, sidePad, colGap, rowGap),
              const SizedBox(height: bottomPad),
            ],
          );
        },
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatNumber(_dialedNumber),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textBlue,
                        letterSpacing: 1.2,
                      ),
                    ),
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
    final hasQuery = _dialedNumber.replaceAll(RegExp(r'\D'), '').isNotEmpty ||
        _dialedNumber.contains('+');

    if (!hasQuery) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<ContactsBloc, ContactsState>(
      builder: (context, state) {
        if (state is ContactsLoading || state is ContactsInitial) {
          return const SizedBox.shrink();
        }
        if (state is! ContactsLoaded) {
          return const SizedBox.shrink();
        }

        final items = _suggestionsFor(state.allContacts, _dialedNumber);
        if (items.isEmpty) {
          return Center(
            child: Text(
              'No matching contacts',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 6),
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
          );
      },
    );
  }

  Widget _buildIosKeypad(
    double keySize,
    double sidePad,
    double colGap,
    double rowGap,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sidePad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iosKeyRow(['1', '2', '3'], keySize, colGap),
          SizedBox(height: rowGap),
          _iosKeyRow(['4', '5', '6'], keySize, colGap),
          SizedBox(height: rowGap),
          _iosKeyRow(['7', '8', '9'], keySize, colGap),
          SizedBox(height: rowGap),
          _iosKeyRow(['*', '0', '#'], keySize, colGap),
          SizedBox(height: rowGap),
          _iosBottomRow(keySize, colGap),
        ],
      ),
    );
  }

  Widget _iosKeyRow(List<String> labels, double keySize, double colGap) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) SizedBox(width: colGap),
          _buildKey(labels[i], keySize),
        ],
      ],
    );
  }

  Widget _iosBottomRow(double keySize, double colGap) {
    return Row(
      children: [
        SizedBox(width: keySize, height: keySize),
        SizedBox(width: colGap),
        SizedBox(
          width: keySize,
          height: keySize,
          child: Material(
            color: Colors.green,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _isCalling ? null : () => _makeCall(),
              child: Center(
                child: _isCalling
                    ? SizedBox(
                        width: keySize * 0.35,
                        height: keySize * 0.35,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.phone, color: Colors.white, size: keySize * 0.44),
              ),
            ),
          ),
        ),
        SizedBox(width: colGap),
        SizedBox(
          width: keySize,
          height: keySize,
          child: _dialedNumber.isNotEmpty
              ? IconButton(
                  onPressed: _onDelete,
                  onLongPress: _onDeleteLongPressed,
                  icon: Icon(
                    Icons.backspace_outlined,
                    size: keySize * 0.36,
                    color: AppColors.textBlue.withValues(alpha: 0.55),
                  ),
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildKey(String label, double size) {
    var subLabel = '';
    switch (label) {
      case '2':
        subLabel = 'ABC';
        break;
      case '3':
        subLabel = 'DEF';
        break;
      case '4':
        subLabel = 'GHI';
        break;
      case '5':
        subLabel = 'JKL';
        break;
      case '6':
        subLabel = 'MNO';
        break;
      case '7':
        subLabel = 'PQRS';
        break;
      case '8':
        subLabel = 'TUV';
        break;
      case '9':
        subLabel = 'WXYZ';
        break;
      case '0':
        subLabel = '+';
        break;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          splashColor: AppColors.primaryBlue.withValues(alpha: 0.08),
          highlightColor: AppColors.primaryBlue.withValues(alpha: 0.04),
          onTap: () => _onNumberTapped(label),
          onLongPress: label == '0' ? () => _onNumberLongPressed(label) : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                  color: AppColors.textBlue,
                ),
              ),
              if (subLabel.isNotEmpty) ...[
                SizedBox(height: size * 0.02),
                Text(
                  subLabel,
                  style: TextStyle(
                    fontSize: label == '0' ? size * 0.14 : size * 0.11,
                    height: 1.0,
                    color: AppColors.textBlue.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                    letterSpacing: label == '0' ? 0 : 1.8,
                  ),
                ),
              ] else
                SizedBox(height: size * 0.14),
            ],
          ),
        ),
      ),
    );
  }
}
