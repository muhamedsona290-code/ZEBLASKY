import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'elder_screen.dart';
import 'family_screen.dart';
import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  final role = (await SharedPreferences.getInstance()).getString('role');
  runApp(KoodeApp(role: role));
}

SupabaseClient get db => Supabase.instance.client;

class KoodeApp extends StatefulWidget {
  final String? role;
  const KoodeApp({super.key, this.role});
  @override
  State<KoodeApp> createState() => _KoodeAppState();
}

class _KoodeAppState extends State<KoodeApp> {
  String? role;
  bool _splashFinished = false;

  @override
  void initState() {
    super.initState();
    role = widget.role;
  }

  Future<void> pick(String? r) async {
    final p = await SharedPreferences.getInstance();
    if (r == null) {
      await p.remove('role');
    } else {
      await p.setString('role', r);
    }
    setState(() => role = r);
  }

  Widget _buildRolePicker() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: 130,
                      height: 130,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'കൂടെ  ·  KOODE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Color(0xFF1E382B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Which phone is this?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF5A665E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 36),

                // Elder Phone Option
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFC8DEC9), width: 1.2),
                  ),
                  color: const Color(0xFFE8F2E8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => pick('elder'),
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Color(0xFF315B4B),
                            child: Icon(Icons.favorite, color: Colors.white, size: 28),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Elder Phone',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E382B)),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Lakshmi Amma screen • Big touch buttons & voice prompt calls',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF4A554E)),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF315B4B)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Family Phone Option
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  color: Colors.white,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => pick('family'),
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Color(0xFF5C715E),
                            child: Icon(Icons.family_restroom, color: Colors.white, size: 28),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Family Phone',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E382B)),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Guardian dashboard • Call scheduler, recorded questions & alerts',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF5A665E)),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF5C715E)),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'Tip: You can switch roles at any time using the ⇄ icon in the top right.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreen() {
    if (role == 'elder') {
      return ElderScreen(onSwitch: () => pick(null));
    }
    if (role == 'family') {
      return FamilyScreen(onSwitch: () => pick(null));
    }
    return _buildRolePicker();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koode',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF315B4B)),
        scaffoldBackgroundColor: const Color(0xFFF7F4EC),
        fontFamily: 'Roboto',
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: !_splashFinished
            ? SplashScreen(
                key: const ValueKey('splash_screen'),
                onFinished: () => setState(() => _splashFinished = true),
              )
            : KeyedSubtree(
                key: ValueKey(role ?? 'role_picker'),
                child: _buildScreen(),
              ),
      ),
    );
  }
}
