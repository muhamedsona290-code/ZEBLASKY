import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'elder_screen.dart';
import 'family_screen.dart';
import 'theme/koode_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  final role = (await SharedPreferences.getInstance()).getString('role');
  runApp(KoodeApp(role: role));
}

SupabaseClient get db => Supabase.instance.client;

class KoodeApp extends StatefulWidget {
  final String? role;
  const KoodeApp({super.key, this.role});
  @override
  State<KoodeApp> createState() => _S();
}

class _S extends State<KoodeApp> {
  String? role;
  @override
  void initState() { super.initState(); role = widget.role; }
  Future<void> pick(String? r) async {
    final p = await SharedPreferences.getInstance();
    r == null ? await p.remove('role') : await p.setString('role', r);
    setState(() => role = r);
  }
  @override
  Widget build(BuildContext c) => MaterialApp(
        title: 'Koode',
        debugShowCheckedModeBanner: false,
        theme: KoodeTheme.theme,
        home: role == 'elder' ? ElderScreen(onSwitch: () => pick(null))
            : role == 'family' ? FamilyScreen(onSwitch: () => pick(null))

            : Scaffold(body: SafeArea(child: Padding(padding: const EdgeInsets.all(24),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('കൂടെ  Koode', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Which phone is this?', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 32),
                  FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(0, 64)), onPressed: () => pick('elder'), child: const Text("Elder phone (Lakshmi Amma)", style: TextStyle(fontSize: 18))),
                  const SizedBox(height: 16),
                  FilledButton.tonal(style: FilledButton.styleFrom(minimumSize: const Size(0, 64)), onPressed: () => pick('family'), child: const Text('Family phone', style: TextStyle(fontSize: 18))),
                ])))),
      );
}
