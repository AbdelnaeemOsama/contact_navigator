import 'package:flutter/material.dart';
import 'package:contact_navigator/core/utils/text_utils.dart';

/// Search field for the contacts list; keeps its own [TextEditingController] and
/// reports text changes to the parent (typically to drive [SearchContactsEvent]).
class ContactsSearchBar extends StatefulWidget {
  final ValueChanged<String> onQueryChanged;

  const ContactsSearchBar({
    super.key,
    required this.onQueryChanged,
  });

  @override
  State<ContactsSearchBar> createState() => _ContactsSearchBarState();
}

class _ContactsSearchBarState extends State<ContactsSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, child) {
              return Directionality(
                textDirection: TextUtils.getTextDirection(value.text),
                child: TextField(
                  controller: _controller,
                  onChanged: widget.onQueryChanged,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Search contacts',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey, size: 24),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
