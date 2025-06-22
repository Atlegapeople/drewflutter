import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'screens/lock_screen.dart';
import 'services/authentication_service.dart';
import 'services/inventory_service.dart';
import 'services/sound_service.dart';
import 'services/file_card_service.dart';
import 'services/dispense_service.dart';
import 'widgets/screensaver_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations to landscape for vending machine display
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Hide status bar for full-screen experience
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  
  // Set system overlay style for dark mode
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthenticationService()),
        ChangeNotifierProvider(create: (_) => InventoryService()),
        ChangeNotifierProvider(create: (_) => SoundService()),
        ChangeNotifierProvider(create: (_) => FileCardService()),
        ChangeNotifierProvider(create: (_) => DispenseService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'D.R.E.W. Vending Machine',
        theme: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFFF48FB1), // Pink as primary color
            secondary: const Color(0xFFF48FB1),
            surface: const Color(0xFF121212),
            background: const Color(0xFF121212),
            onPrimary: Colors.white,
          ),
          useMaterial3: true,
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 32.0, 
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            headlineMedium: TextStyle(
              fontSize: 24.0, 
              fontWeight: FontWeight.bold,
            ),
            bodyLarge: TextStyle(fontSize: 18.0),
            bodyMedium: TextStyle(fontSize: 16.0),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: const ScreensaverOverlay(
          child: LockScreen(),
        ),
      ),
    );
  }
}
