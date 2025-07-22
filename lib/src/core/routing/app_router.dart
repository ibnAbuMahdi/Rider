import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../features/auth/screens/phone_input_screen.dart';
import '../../features/auth/screens/otp_verification_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/campaigns/screens/campaign_list_screen.dart';
import '../../features/verification/screens/verification_screen.dart';
import '../../features/earnings/screens/earnings_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../models/verification_request.dart';

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/auth/phone',
    redirect: (context, state) {
      if (kDebugMode) {
        print('🔄 ROUTER DEBUG: location=${state.matchedLocation}');
      }
      try {
        final container = ProviderScope.containerOf(context);
        final authState = container.read(authProvider);
        
        if (kDebugMode) {
          print('🔄 AUTH STATE: isAuth=${authState.isAuthenticated}, rider=${authState.rider?.id}');
        }
	
 
      // Get auth state from container instead of watching to prevent rebuilds
      //final container = ProviderScope.containerOf(context);
      //final authState = container.read(authProvider);
      
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final rider = authState.rider;
      final location = state.matchedLocation;
      
      // Show loading if auth is being checked
      if (isLoading) return null;
      
      // Prevent redirect loops
      if (location == '/' && !isAuthenticated) {
        return '/auth/phone';
      }
      if (location == '/' && isAuthenticated && rider?.hasCompletedOnboarding == true) {
        return '/home';
      }
      if (location == '/' && isAuthenticated && rider?.hasCompletedOnboarding != true) {
        return '/onboarding';
      }
      
      // Auth routes
      final isAuthRoute = location.startsWith('/auth');
      
      if (!isAuthenticated) {
        // Not authenticated, redirect to auth unless already there
        return isAuthRoute ? null : '/auth/phone';
      }
      
      // Authenticated but on auth route, redirect to appropriate screen
      if (isAuthRoute) {
        if (rider?.hasCompletedOnboarding == true) {
          return '/home';
        } else {
          return '/onboarding';
        }
      }
      
      // Check onboarding completion
      final isOnboardingRoute = location.startsWith('/onboarding');
      
      if (rider?.hasCompletedOnboarding != true && !isOnboardingRoute) {
        return '/onboarding';
      }
      
      if (rider?.hasCompletedOnboarding == true && isOnboardingRoute) {
        return '/home';
      }
      
      return null;
	  } catch (e) {
		print('🔴 ROUTER ERROR: $e');
		print('🔴 STACK: ${StackTrace.current}');
		return '/auth/phone'; // Safe fallback
	}

    },
    routes: [
      // Root route
      GoRoute(
        path: '/',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      
      // Auth routes
      GoRoute(
        path: '/auth/phone',
        builder: (context, state) => const PhoneInputScreen(),
      ),
      GoRoute(
        path: '/auth/verify-otp',
        builder: (context, state) {
          final phoneNumber = state.extra as String?;
          if (phoneNumber == null) {
            return const PhoneInputScreen();
          }
          return OTPVerificationScreen(phoneNumber: phoneNumber);
        },
      ),
      
      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Main app routes
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/campaigns',
            builder: (context, state) => const CampaignListScreen(),
          ),
          GoRoute(
            path: '/earnings',
            builder: (context, state) => const EarningsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      
      // Verification screen (modal)
      GoRoute(
        path: '/verification',
        pageBuilder: (context, state) {
          final request = state.extra as VerificationRequest?;
          return MaterialPage(
            fullscreenDialog: true,
            child: VerificationScreen(request: request),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Navigation shell for bottom navigation
class MainNavigationShell extends StatelessWidget {
  final Widget child;
  
  const MainNavigationShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _getCurrentIndex(context),
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign),
            label: 'Campaigns',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/campaigns')) return 1;
    if (location.startsWith('/earnings')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/campaigns');
        break;
      case 2:
        context.go('/earnings');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}