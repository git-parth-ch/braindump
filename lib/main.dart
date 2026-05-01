import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/note_provider.dart';
import 'screens/home_screen.dart';
import 'screens/note_editor.dart';
import 'widgets/crt_effect.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('notes_box');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NoteProvider()..loadNotes()),
      ],
      child: const MyApp(),
    ),
  );
}

class QuickActionsManager {
  static final QuickActions quickActions = const QuickActions();

  static void init(BuildContext context) {
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(type: 'new_note', localizedTitle: 'New Note', icon: 'add'),
      const ShortcutItem(type: 'new_checklist', localizedTitle: 'New Checklist', icon: 'checklist'),
      const ShortcutItem(type: 'voice_note', localizedTitle: 'Voice Note', icon: 'mic'),
    ]);

    quickActions.initialize((shortcutType) {
      if (shortcutType == 'new_note') {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NoteEditor()));
      } else if (shortcutType == 'new_checklist') {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NoteEditor()));
      } else if (shortcutType == 'voice_note') {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NoteEditor()));
      }
    });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteProvider>(
      builder: (context, noteProvider, child) {
        // Initialize quick actions after the first frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          QuickActionsManager.init(context);
        });

        final isRetro = noteProvider.isRetroTheme;

        return MaterialApp(
          title: 'brain_dump.log',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
          ],
          theme: isRetro
              ? ThemeData(
                  brightness: Brightness.dark,
                  scaffoldBackgroundColor: Colors.black,
                  primaryColor: const Color(0xFF00FF41),
                  textTheme: GoogleFonts.vt323TextTheme(ThemeData.dark().textTheme).apply(
                    bodyColor: const Color(0xFF00FF41),
                    displayColor: const Color(0xFF00FF41),
                  ),
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF00FF41),
                    surface: Colors.black,
                    onSurface: Color(0xFF00FF41),
                  ),
                )
              : ThemeData(
                  brightness: Brightness.light,
                  primarySwatch: Colors.blue,
                  useMaterial3: true,
                  fontFamily: 'Roboto',
                ),
          darkTheme: isRetro
              ? null
              : ThemeData(
                  brightness: Brightness.dark,
                  primarySwatch: Colors.blue,
                  useMaterial3: true,
                  fontFamily: 'Roboto',
                  scaffoldBackgroundColor: const Color(0xFF0F0F1E),
                ),
          themeMode: isRetro ? ThemeMode.dark : ThemeMode.system,
          home: CRTEffect(
            enabled: isRetro && noteProvider.isCRTEnabled,
            child: const HomeScreen(),
          ),
        );
      },
    );
  }
}
