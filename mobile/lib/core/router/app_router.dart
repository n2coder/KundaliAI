import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/phone_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/loading_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/horoscope/presentation/horoscope_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/insights/presentation/insight_detail_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/remedies/presentation/remedies_screen.dart';
import '../../features/remedies/presentation/all_remedies_screen.dart';
import '../../features/remedies/presentation/remedy_detail_screen.dart';
import '../../features/birth_chart/presentation/birth_chart_screen.dart';
import '../../features/birth_chart/presentation/birth_details_screen.dart';
import '../../features/today/presentation/explore_today_screen.dart';
import '../../features/transit/presentation/planetary_transit_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/guidance/presentation/guidance_screen.dart';
import '../../features/compatibility/presentation/compatibility_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  routes: [
    // ── Auth flow ───────────────────────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/phone',
      builder: (_, __) => const PhoneScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final phone = state.uri.queryParameters['phone'] ?? '';
        final verificationId = state.uri.queryParameters['vid'] ?? '';
        return OtpScreen(phone: phone, verificationId: verificationId);
      },
    ),
    GoRoute(
      path: '/loading',
      builder: (_, __) => const LoadingScreen(),
    ),
    GoRoute(
      path: '/birth-details',
      builder: (_, __) => const BirthDetailsScreen(),
    ),

    // ── Main app ────────────────────────────────────────────────────────────
    GoRoute(
      path: '/home',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/horoscope',
      builder: (_, __) => const HoroscopeScreen(),
    ),
    GoRoute(
      path: '/birth-chart',
      builder: (_, __) => const BirthChartScreen(),
    ),
    GoRoute(
      path: '/compatibility',
      builder: (_, __) => const CompatibilityScreen(),
    ),

    // ── Insights ────────────────────────────────────────────────────────────
    GoRoute(
      path: '/insights',
      builder: (_, __) => const InsightsScreen(),
    ),
    GoRoute(
      path: '/insights/:tab',
      builder: (context, state) {
        final tab = state.pathParameters['tab'] ?? 'Love';
        return InsightDetailScreen(tab: tab);
      },
    ),

    // ── Chat ────────────────────────────────────────────────────────────────
    GoRoute(
      path: '/chat',
      builder: (_, __) => const ChatScreen(),
    ),

    // ── Remedies ────────────────────────────────────────────────────────────
    GoRoute(
      path: '/remedies',
      builder: (_, __) => const RemediesScreen(),
    ),
    GoRoute(
      path: '/remedies/all',
      builder: (_, __) => const AllRemediesScreen(),
    ),
    GoRoute(
      path: '/remedies/:title',
      builder: (context, state) {
        final title =
            Uri.decodeComponent(state.pathParameters['title'] ?? '');
        return RemedyDetailScreen(title: title);
      },
    ),

    // ── Explore Today ───────────────────────────────────────────────────────
    GoRoute(
      path: '/explore-today',
      builder: (_, __) => const ExploreTodayScreen(),
    ),

    // ── Planetary Transits ──────────────────────────────────────────────────
    GoRoute(
      path: '/transits',
      builder: (_, __) => const PlanetaryTransitScreen(),
    ),

    // ── Profile ─────────────────────────────────────────────────────────────
    GoRoute(
      path: '/profile',
      builder: (_, __) => const ProfileScreen(),
    ),

    // ── Guidance ────────────────────────────────────────────────────────────
    GoRoute(
      path: '/guidance',
      builder: (_, __) => const GuidanceScreen(),
    ),
  ],

  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri}',
          style: const TextStyle(color: Colors.white)),
    ),
  ),
);
