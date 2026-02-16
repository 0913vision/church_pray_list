import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/version_check_provider.dart';
import '../../presentation/screens/loading/loading_screen.dart';
import '../../presentation/screens/login/login_screen.dart';
import '../../presentation/screens/main/main_screen.dart';
import '../../presentation/screens/edit/edit_screen.dart';
import '../../presentation/screens/unauthorized/unauthorized_screen.dart';
import '../../presentation/screens/update_required/update_required_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final versionState = ref.watch(versionCheckProvider);

  return GoRouter(
    initialLocation: '/loading',
    redirect: (context, state) {
      final path = state.uri.path;

      // 1. Auth is loading
      if (authState.loading) {
        return path == '/loading' ? null : '/loading';
      }

      // 2. Not logged in
      if (authState.user == null) {
        return path == '/login' ? null : '/login';
      }

      // 3. Permission not yet checked
      if (authState.isAllowedUser == null) {
        return path == '/loading' ? null : '/loading';
      }

      // 4. Not allowed
      if (authState.isAllowedUser == false) {
        return path == '/unauthorized' ? null : '/unauthorized';
      }

      // 5. Version check in progress
      if (versionState.isChecking) {
        return path == '/loading' ? null : '/loading';
      }

      // 6. Update required
      if (versionState.isUpdateRequired) {
        return path == '/update-required' ? null : '/update-required';
      }

      // 7. All checks passed - allow /main and /edit
      if (path == '/loading' ||
          path == '/login' ||
          path == '/unauthorized' ||
          path == '/update-required') {
        return '/main';
      }

      return null; // no redirect needed
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) {
          // Determine loading message based on auth state
          String message = '\uC0AC\uC6A9\uC790 \uC815\uBCF4\uB97C \uD655\uC778\uD558\uACE0 \uC788\uC5B4\uC694';
          final auth = ref.read(authProvider);
          final version = ref.read(versionCheckProvider);

          if (auth.user != null && auth.isAllowedUser == null) {
            message = '\uAD8C\uD55C\uC744 \uD655\uC778\uD558\uACE0 \uC788\uC5B4\uC694';
          } else if (auth.user != null &&
              auth.isAllowedUser == true &&
              version.isChecking) {
            message = '\uCD5C\uC2E0 \uBC84\uC804\uC744 \uD655\uC778\uD558\uACE0 \uC788\uC5B4\uC694';
          }

          return LoadingScreen(message: message);
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/edit',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const EditScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Bottom-to-top slide transition
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/unauthorized',
        builder: (context, state) => const UnauthorizedScreen(),
      ),
      GoRoute(
        path: '/update-required',
        builder: (context, state) => const UpdateRequiredScreen(),
      ),
    ],
  );
});
