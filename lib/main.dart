import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Core imports
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/constants/app_constants.dart';

// Data imports
import 'data/services/database_helper.dart';

// Presentation imports
import 'presentation/screens/home_screen.dart';
import 'presentation/providers/song_provider.dart';
import 'presentation/providers/repertoire_provider.dart';
import 'presentation/providers/export_provider.dart';
import 'presentation/providers/theme_provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final databaseHelper = DatabaseHelper();
  await databaseHelper.database; // Initialize database on app start

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SongProvider()),
        ChangeNotifierProvider(create: (_) => RepertoireProvider()),
        ChangeNotifierProvider(create: (_) => ExportProvider()),
      ],
      child: const MyFakeBookApp(),
    ),
  );
}

/// Main application widget
class MyFakeBookApp extends StatelessWidget {
  const MyFakeBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: child,
        );
      },
      child: const SplashScreen(),
    );
  }
}

/// Splash screen with app branding
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize app data and navigate to home screen
  Future<void> _initializeApp() async {
    // Simulate initialization process
    await Future.delayed(2.seconds);

    // Load initial data
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final repertoireProvider = Provider.of<RepertoireProvider>(
      context,
      listen: false,
    );

    try {
      await songProvider.loadSongs();
      await repertoireProvider.loadRepertoires();
    } catch (e) {
      print('Error loading initial data: $e');
      // Continue to home screen even if data loading fails
    }

    // Navigate to home screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.primary),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/icon
            Container(
                  width: 120.w,
                  height: 120.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withOpacity(0.2),
                        blurRadius: 20.r,
                        offset: Offset(0, 10.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.music_note,
                    size: 60.sp,
                    color: Color(AppColors.primary),
                  ),
                )
                .animate()
                .scale(duration: 800.ms)
                .then(delay: 200.ms)
                .shake(duration: 600.ms),

            SizedBox(height: 32.h),

            // App name
            Text(
              AppConstants.appName,
              style: GoogleFonts.roboto(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),

            SizedBox(height: 8.h),

            // App description
            Text(
              AppConstants.appDescription,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),

            SizedBox(height: 48.h),

            // Loading indicator
            Container(
                  width: 40.w,
                  height: 40.h,
                  padding: EdgeInsets.all(8.r),
                  child: CircularProgressIndicator(
                    strokeWidth: 3.w,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8),
                    ),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .rotate(duration: 1500.ms),

            SizedBox(height: 24.h),

            // Loading text
            Text(
                  'Initializing...',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white60,
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .fade(duration: 1000.ms, curve: Curves.easeInOut),
          ],
        ),
      ),
    );
  }
}

/// Error screen for handling app initialization failures
class ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ErrorScreen({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
              SizedBox(height: 24.h),
              Text(
                'Oops! Something went wrong',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                error,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppColors.primary),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: () {
                  // TODO: Show app info or contact support
                },
                child: Text(
                  'Need Help?',
                  style: GoogleFonts.roboto(
                    color: Color(AppColors.primary),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// App wrapper with error handling
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _hasError = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return ErrorScreen(error: _errorMessage, onRetry: _retryApp);
    }

    return const MyFakeBookApp();
  }

  void _retryApp() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
  }

  void _handleError(String error) {
    setState(() {
      _hasError = true;
      _errorMessage = error;
    });
  }
}

// Error handling wrapper (commented out for now, can be used for production)
/*
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SongProvider()),
      ],
      child: const AppWrapper(),
    ),
  );
}
*/
