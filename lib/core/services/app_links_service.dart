import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';

class AppLinksService {
  final AppLinks _appLinks;
  final ContactsBloc _contactsBloc;
  StreamSubscription<Uri>? _linkSubscription;

  AppLinksService(this._contactsBloc) : _appLinks = AppLinks();

  void init() {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    _handleInitialUri();
  }

  Future<void> _handleInitialUri() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Failed to receive initial uri: $e');
    }
  }

  void _handleDeepLink(Uri uri) async {
    debugPrint('Received Deep Link: $uri');
    if (uri.scheme == 'contactnavigator') {
      if (uri.host == 'call') {
        final name = uri.queryParameters['name'] ?? '';
        if (name.isNotEmpty) {
          _handleCallCommand(name);
        }
      } else if (uri.host == 'navigate') {
        final destination = uri.queryParameters['destination'] ?? '';
        if (destination.isNotEmpty) {
          _handleNavigateCommand(destination);
        }
      }
    }
  }

  void _handleCallCommand(String name) async {
    final state = _contactsBloc.state;
    if (state is ContactsLoaded) {
      final lowerName = name.toLowerCase();
      final matches = state.allContacts.where((c) {
        return c.displayName?.toLowerCase().contains(lowerName) ?? false;
      }).toList();

      if (matches.isNotEmpty) {
        final contact = matches.first;
        if (contact.phones.isNotEmpty) {
          final phone = contact.phones.first.number;
          await FlutterPhoneDirectCaller.callNumber(phone);
        }
      }
    }
  }

  void _handleNavigateCommand(String destination) async {
    // Attempt to parse location link if exists, otherwise open GMaps with query
    final state = _contactsBloc.state;
    if (state is ContactsLoaded) {
      final lowerName = destination.toLowerCase();
      final matches = state.allContacts.where((c) {
        return c.displayName?.toLowerCase().contains(lowerName) ?? false;
      }).toList();

      if (matches.isNotEmpty) {
        final contact = matches.first;
        if (contact.websites.isNotEmpty) {
          final link = contact.websites.first.url;
          if (link.isNotEmpty) {
            final uri = Uri.parse(link);
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              return;
            } catch (_) {}
          }
        }
      }
    }

    // Fallback: Just open Google Maps with the query
    final uri = Uri.parse('google.navigation:q=${Uri.encodeComponent(destination)}');
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
