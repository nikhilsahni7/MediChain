import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemUiOverlayStyle
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:medileger/config/router/app_router.dart';
import 'package:medileger/core/providers/shared_preferences_provider.dart';

// import 'package:medileger/config/theme/app_theme.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  void _onOnboardingComplete(BuildContext context, WidgetRef ref) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool('hasSeenOnboarding', true);
      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preference: $e')),
        );
      }
    }
  }

  // Helper to build image widget (simplified, assuming assets are valid)
  Widget _buildImage(BuildContext context, String assetPath) {
    // Use a container with theme background while loading or if error
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 250,
      width: 250,
      decoration: BoxDecoration(
        color: colorScheme.surface
            .withOpacity(0.5), // Slightly transparent surface
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Image.asset(
          assetPath,
          height: 250,
          width: 250,
          fit: BoxFit.contain,
          // Optional: Add frameBuilder for smooth loading indicator
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print("Error loading image $assetPath: $error");
            return Icon(
              Icons.broken_image_outlined,
              size: 80,
              color: colorScheme.onSurface.withOpacity(0.3),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Use theme text styles directly where possible
    final pageDecoration = PageDecoration(
      titleTextStyle: textTheme.headlineMedium!.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
        height: 1.3,
      ),
      bodyTextStyle: textTheme.bodyLarge!.copyWith(
        color: colorScheme.onSurface.withOpacity(0.85), // Use onBackground
        height: 1.5,
      ),
      // Use theme background/surface colors
      pageColor: colorScheme.surface, // Match scaffold background
      imagePadding: const EdgeInsets.only(top: 40, bottom: 24),
      bodyPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      footerPadding: const EdgeInsets.all(24.0),
      imageFlex: 3,
      bodyFlex: 2,
    );

    // Define SystemUiOverlayStyle based on theme
    final systemUiStyle = SystemUiOverlayStyle(
      // Status bar color (usually transparent or matches background)
      statusBarColor: Colors.transparent,
      // Status bar icon brightness
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      // Navigation bar color (can match background or surface)
      systemNavigationBarColor: colorScheme.surface,
      // Navigation bar icon brightness
      systemNavigationBarIconBrightness:
          isDarkMode ? Brightness.light : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiStyle,
      child: IntroductionScreen(
        key: GlobalKey<IntroductionScreenState>(),
        globalBackgroundColor: colorScheme.surface,
        allowImplicitScrolling: true,
        autoScrollDuration: 3000,
        infiniteAutoScroll: false, // Usually false for onboarding
        safeAreaList: const [
          false,
          false,
          true,
          true
        ], // Adjust safe area as needed
        globalHeader: Padding(
          padding: const EdgeInsets.only(
              top: 60.0, bottom: 20.0), // Add bottom padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.medical_services_outlined,
                  size: 35, color: colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                'MediChain',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        pages: [
          PageViewModel(
            title: "Welcome to MediChain",
            body:
                "Connecting hospitals for efficient medicine sharing, securely and privately.",
            image: _buildImage(context, 'assets/images/welcome.png'),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Find Medicines Fast",
            body:
                "Check real-time availability across network hospitals anonymously.",
            image: _buildImage(context, 'assets/images/search.png'),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Secure & Decentralized",
            body:
                "Using encryption and P2P communication to protect data and ensure reliability.",
            image: _buildImage(context, 'assets/images/security.png'),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Get Started",
            body:
                "Join the network to manage inventory, fulfill requests, and save lives.",
            image: _buildImage(context, 'assets/images/get_started.png'),
            decoration: pageDecoration,
          ),
        ],
        onDone: () => _onOnboardingComplete(context, ref),
        onSkip: () => _onOnboardingComplete(context, ref),
        showSkipButton: true,
        skip: const Text('SKIP'), // Uppercase for consistency
        next: Icon(Icons.arrow_forward_ios_rounded,
            color: colorScheme.primary, size: 20),
        done: const Text('START',
            style: TextStyle(fontWeight: FontWeight.bold)), // Keep bold

        dotsDecorator: DotsDecorator(
          size: const Size.square(8.0),
          activeSize: const Size(20.0, 8.0), // Slightly smaller active dot
          activeColor: colorScheme.primary,
          color: colorScheme.onSurface.withOpacity(0.2), // Use onBackground
          spacing: const EdgeInsets.symmetric(horizontal: 4.0),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        // Customize controls position if needed
        // controlsMargin: const EdgeInsets.all(16),
        // controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      ),
    );
  }

  Widget _buildLottie(String assetPath) {
    try {
      return Center(
        child: Lottie.asset(
          assetPath,
          height: 250,
          width: 250,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            print("Error loading Lottie: $assetPath - $error");
            return const Icon(Icons.error_outline,
                size: 100, color: Colors.redAccent);
          },
        ),
      );
    } catch (e) {
      print("Exception building Lottie: $assetPath - $e");
      return const Icon(Icons.error, size: 100, color: Colors.red);
    }
  }
}
