import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safety_superapp/core/widgets/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Disable runtime HTTP fetching for 100% offline standalone execution
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(
    const ProviderScope(
      child: SafetySuperapp(),
    ),
  );
}

class SafetySuperapp extends StatelessWidget {
  const SafetySuperapp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safety Superapp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
        textTheme: GoogleFonts.promptTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      home: const AppShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
