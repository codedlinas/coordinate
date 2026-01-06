import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/storage/storage_service.dart';
import 'services/foreground_location_service.dart';
import 'state/providers.dart';
import 'state/tracking_provider.dart';
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

class CoordinateApp extends ConsumerStatefulWidget {
  final bool showOnboarding;

  const CoordinateApp({super.key, this.showOnboarding = false});

  @override
  ConsumerState<CoordinateApp> createState() => _CoordinateAppState();
}

class _CoordinateAppState extends ConsumerState<CoordinateApp> with WidgetsBindingObserver {
  bool _bgServiceInitialized = false;

  @override
  void initState() {
    super.initState();
    // Register lifecycle observer for iOS foreground tracking
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize background location service after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBackgroundService();
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // When app comes to foreground, check location (especially important for iOS)
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }
  
  Future<void> _onAppResumed() async {
    if (!_bgServiceInitialized) return;
    
    try {
      final bgService = ref.read(backgroundLocationServiceProvider);
      await bgService.onAppResumed();
    } catch (e) {
      debugPrint('Error in onAppResumed: $e');
    }
  }

  Future<void> _initBackgroundService() async {
    if (_bgServiceInitialized) return;
    _bgServiceInitialized = true;
    
    try {
      // Initialize background location service (WorkManager)
      final bgService = ref.read(backgroundLocationServiceProvider);
      await bgService.initialize();
      debugPrint('BackgroundLocationService initialized successfully');
      
      // Initialize foreground service on Android
      if (ForegroundLocationService.isSupported) {
        final fgService = ref.read(foregroundLocationServiceProvider);
        await fgService.initialize();
        debugPrint('ForegroundLocationService initialized successfully');
      }
      
      // Initialize tracking service and restore previous tracking state
      final trackingService = ref.read(trackingServiceProvider);
      await trackingService.initialize();
      debugPrint('TrackingService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize location services: $e');
      // Don't crash the app - background tracking is optional
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coordinate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: widget.showOnboarding
          ? const PhoneWrapper(child: OnboardingScreen())
          : const PhoneWrapper(child: HomeScreen()),
    );
  }
}
