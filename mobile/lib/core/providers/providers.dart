import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/birth_chart_model.dart';
import '../models/horoscope_model.dart';
import '../models/insight_model.dart';
import '../models/remedy_model.dart';
import '../models/today_model.dart';
import '../models/transit_model.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/birth_chart/data/birth_chart_repository.dart';
import '../../features/horoscope/data/horoscope_repository.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/insights/data/insights_repository.dart';
import '../../features/remedies/data/remedies_repository.dart';
import '../../features/today/data/today_repository.dart';
import '../../features/transit/data/transit_repository.dart';
import '../../features/compatibility/data/compatibility_repository.dart';
import 'auth_provider.dart';

// ── Repository providers ──────────────────────────────────────────────────────

final authRepoProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

final birthChartRepoProvider = Provider<BirthChartRepository>(
  (ref) => BirthChartRepository(ref.watch(dioProvider)),
);

final horoscopeRepoProvider = Provider<HoroscopeRepository>(
  (ref) => HoroscopeRepository(ref.watch(dioProvider)),
);

final chatRepoProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(dioProvider)),
);

final insightsRepoProvider = Provider<InsightsRepository>(
  (ref) => InsightsRepository(ref.watch(dioProvider)),
);

final remediesRepoProvider = Provider<RemediesRepository>(
  (ref) => RemediesRepository(ref.watch(dioProvider)),
);

final todayRepoProvider = Provider<TodayRepository>(
  (ref) => TodayRepository(ref.watch(dioProvider)),
);

final transitRepoProvider = Provider<TransitRepository>(
  (ref) => TransitRepository(ref.watch(dioProvider)),
);

final compatibilityRepoProvider = Provider<CompatibilityRepository>(
  (ref) => CompatibilityRepository(ref.watch(dioProvider)),
);

// ── Feature data providers ────────────────────────────────────────────────────

final dailyHoroscopeProvider =
    FutureProvider.autoDispose<HoroscopeModel>((ref) {
  return ref.watch(horoscopeRepoProvider).getDaily();
});

final weeklyHoroscopeProvider =
    FutureProvider.autoDispose<HoroscopeModel>((ref) {
  return ref.watch(horoscopeRepoProvider).getWeekly();
});

final monthlyHoroscopeProvider =
    FutureProvider.autoDispose<HoroscopeModel>((ref) {
  return ref.watch(horoscopeRepoProvider).getMonthly();
});

final allInsightsProvider =
    FutureProvider.autoDispose<List<InsightModel>>((ref) {
  return ref.watch(insightsRepoProvider).getAllInsights();
});

final remediesProvider =
    FutureProvider.autoDispose<List<RemedyModel>>((ref) {
  return ref.watch(remediesRepoProvider).getRemedies();
});

final todayProvider = FutureProvider.autoDispose<TodayModel>((ref) {
  return ref.watch(todayRepoProvider).getToday();
});

final birthChartProvider =
    FutureProvider.autoDispose<BirthChartModel>((ref) {
  return ref.watch(birthChartRepoProvider).getChart();
});

final transitsProvider =
    FutureProvider.autoDispose<List<TransitModel>>((ref) {
  return ref.watch(transitRepoProvider).getTransits();
});
