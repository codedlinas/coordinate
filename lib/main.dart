import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/storage/storage_service.dart';
import 'ui/screens/screens.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/phone_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize storage
  await StorageService.init();

  // Check if onboarding has been shown
  final onboardingBox = await Hive.openBox('app_preferences');
  final hasSeenOnboarding = onboardingBox.get('hasSeenOnboarding', defaultValue: false) as bool;

  runApp(ProviderScope(
    child: CoordinateApp(showOnboarding: !hasSeenOnboarding),
  ));
}

class CoordinateApp extends StatelessWidget {
  final bool showOnboarding;

  const CoordinateApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coordinate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: showOnboarding
          ? const PhoneWrapper(child: OnboardingScreen())
          : const PhoneWrapper(child: HomeScreen()),
    );
  }
}
