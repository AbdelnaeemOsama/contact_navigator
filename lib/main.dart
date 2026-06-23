import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/core/services/contact_service.dart';
import 'package:contact_navigator/core/services/group_service.dart';
import 'package:contact_navigator/core/services/voice_service.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_event.dart';
import 'package:contact_navigator/features/contacts/bloc/categories_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/categories_event.dart';
import 'package:contact_navigator/features/voice_assistant/bloc/voice_assistant_bloc.dart';
import 'package:contact_navigator/features/voice_assistant/services/voice_assistant_service.dart';
import 'package:contact_navigator/core/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:contact_navigator/core/services/settings_service.dart';
import 'package:contact_navigator/core/services/app_links_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settingsService = SettingsService(prefs);
  runApp(ContactNavigatorApp(settingsService: settingsService, prefs: prefs));
}

class ContactNavigatorApp extends StatelessWidget {
  final SettingsService settingsService;
  final SharedPreferences prefs;
  const ContactNavigatorApp({
    super.key,
    required this.settingsService,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<IContactService>(create: (_) => ContactService()),
        RepositoryProvider<IGroupService>(create: (_) => GroupService(prefs)),
        RepositoryProvider<SettingsService>(create: (_) => settingsService),
        RepositoryProvider<VoiceAssistantService>(
          create: (_) => VoiceAssistantService(settingsService)..init(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ContactsBloc(
              context.read<IContactService>(),
              context.read<SettingsService>(),
              context.read<IGroupService>(),
            )..add(const LoadContactsEvent()),
          ),
          BlocProvider(
            create: (context) =>
                CategoriesBloc(context.read<IGroupService>())
                  ..add(LoadCategoriesEvent()),
          ),
          BlocProvider(
            create: (context) => VoiceAssistantBloc(
              contactsBloc: context.read<ContactsBloc>(),
              service: VoiceCommandService(
                onNavigate: (contact) async {
                  final phones = contact.phones;
                  if (phones.isNotEmpty) {
                    final link = contact.websites.isNotEmpty
                        ? contact.websites.first.url
                        : '';
                    if (link.isNotEmpty) {
                      // Navigation handled by map route
                    }
                  }
                },
              ),
            ),
          ),
        ],
        child: const AppInitializer(),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late final AppLinksService _appLinksService;

  @override
  void initState() {
    super.initState();
    _appLinksService = AppLinksService(context.read<ContactsBloc>())..init();
  }

  @override
  void dispose() {
    _appLinksService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.generateRoute,
      theme: ThemeData(
        fontFamily: AppFonts.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
        ),
      ),
    );
  }
}
