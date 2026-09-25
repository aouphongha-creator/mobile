import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../app/app_info.dart';
import '../models/models.dart';
import '../services/remote.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import 'seed.dart';

class AppState extends ChangeNotifier {
  AppState({
    Repository? repository,
    Prefs? prefs,
    WeatherService? weather,
    ExchangeService? exchange,
    DateTime Function()? clock,
  }) : _repo = repository ?? LocalRepository(),
       _prefs = prefs ?? Prefs(),
       _weather = weather ?? WeatherService(apiKey: openWeatherApiKey),
       _exchange = exchange ?? ExchangeService(),
       _clock = clock ?? DateTime.now;

  final Repository _repo;
  final Prefs _prefs;
  final WeatherService _weather;
  final ExchangeService _exchange;
  final DateTime Function() _clock;

  bool loaded = false;
  List<Trip> _trips = [];
  List<Activity> _activities = [];
  List<Expense> _expenses = [];
  final Map<String, double> _rates = {};
  final Set<String> _ratesRequested = {};
  final Map<String, Weather?> _weatherCache = {};
  final Set<String> _weatherLoading = {};
  String? _selectedTripId;
  String? _syncError;

  DateTime get now => _clock();

  /// Last failed save/load, shown once as a SnackBar. Reading clears it.
  String? takeSyncError() {
    final e = _syncError;
    _syncError = null;
    return e;
  }

  Future<void> load() async {
    _rates.addAll(await _prefs.loadRates());
    try {
      await _repo.init().timeout(_timeout);
      var data = await _repo.loadAll().timeout(_timeout);
      final empty =
          data.trips.isEmpty &&
          data.activities.isEmpty &&
          data.expenses.isEmpty;
      if (empty && !await _prefs.isSeeded()) {
        data = buildSeed(now, _newId());
        await _repo.insertAll(data).timeout(_timeout);
      }
      await _prefs.markSeeded();
      _trips = data.trips;
      _activities = data.activities;
      _expenses = data.expenses;
    } catch (e) {
      _syncError = 'โหลดข้อมูลไม่สำเร็จ: ${_describe(e)}';
      debugPrint('load failed: $e');
    }
    loaded = true;
    notifyListeners();
  }

  static const _timeout = Duration(seconds: 15);

  /// Short Thai explanation of a repository error for the SnackBar.
  static String _describe(Object e) {
    final text = e.toString();
    if (text.contains('anonymous_provider_disabled')) {
      return 'ยังไม่ได้เปิด Anonymous sign-ins ใน Supabase';
    }
    if (text.contains('row-level security')) {
      return 'ไม่มีสิทธิ์เข้าถึงข้อมูล (ยังไม่ได้เข้าสู่ระบบ Supabase)';
    }
    if (text.contains('PGRST205')) return 'ยังไม่ได้สร้างตารางใน Supabase';
    if (e is TimeoutException) return 'เชื่อมต่อนานเกินไป';
    return 'ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
  }

  /// Runs a repository write; the UI has already been updated optimistically.
  Future<void> _sync(Future<void> Function() write) async {
    try {
      await write().timeout(_timeout);
    } catch (e) {
      _syncError = 'บันทึกข้อมูลไม่สำเร็จ: ${_describe(e)}';
      debugPrint('sync failed: $e');
      notifyListeners();
    }
  }

  // ---------------- Trips ----------------

  /// Ongoing first, then planned (soonest first), then finished.
  List<Trip> get trips {
    int rank(Trip t) => t.statusOn(now).index;
    return [..._trips]..sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      return rank(a) == TripStatus.done.index
          ? b.start.compareTo(a.start)
          : a.start.compareTo(b.start);
    });
  }

  Trip? tripById(String? id) {
    for (final t in _trips) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Trip shown on the Detail and History tabs.
  Trip? get selectedTrip =>
      tripById(_selectedTripId) ?? (trips.isEmpty ? null : trips.first);

  void selectTrip(String id) {
    _selectedTripId = id;
    notifyListeners();
  }

  Future<Trip> saveTrip({
    String? id,
    required String name,
    required String destination,
    required DateTime start,
    required DateTime end,
    required double budget,
    required String currency,
  }) async {
    final existing = tripById(id);
    final trip = existing == null
        ? Trip(
            id: _newId(),
            name: name,
            destination: destination,
            start: dateOnly(start),
            end: dateOnly(end),
            budget: budget,
            currency: currency,
          )
        : existing.copyWith(
            name: name,
            destination: destination,
            start: dateOnly(start),
            end: dateOnly(end),
            budget: budget,
            currency: currency,
          );
    _trips = [..._trips.where((t) => t.id != trip.id), trip];
    notifyListeners();
    await _sync(() => _repo.upsertTrip(trip));
    return trip;
  }

  Future<void> deleteTrip(String id) async {
    _trips.removeWhere((t) => t.id == id);
    _activities.removeWhere((a) => a.tripId == id);
    _expenses.removeWhere((e) => e.tripId == id);
    if (_selectedTripId == id) _selectedTripId = null;
    notifyListeners();
    await _sync(() => _repo.deleteTrip(id));
  }

  // ---------------- Activities ----------------

  List<Activity> activitiesOn(String tripId, DateTime day) =>
      _activities
          .where((a) => a.tripId == tripId && dateOnly(a.date) == dateOnly(day))
          .toList()
        ..sort((a, b) => a.minutes.compareTo(b.minutes));

  Future<void> saveActivity({
    String? id,
    required String tripId,
    required DateTime date,
    required int minutes,
    required String name,
    String note = '',
  }) async {
    final i = _activities.indexWhere((a) => a.id == id);
    final activity = i >= 0
        ? _activities[i].copyWith(minutes: minutes, name: name, note: note)
        : Activity(
            id: _newId(),
            tripId: tripId,
            date: dateOnly(date),
            minutes: minutes,
            name: name,
            note: note,
          );
    if (i >= 0) {
      _activities[i] = activity;
    } else {
      _activities.add(activity);
    }
    notifyListeners();
    await _sync(() => _repo.upsertActivity(activity));
  }

  Future<void> setActivityImage(String id, String path) async {
    final i = _activities.indexWhere((a) => a.id == id);
    if (i < 0) return;
    final activity = _activities[i].copyWith(imagePath: path);
    _activities[i] = activity;
    notifyListeners();
    await _sync(() => _repo.upsertActivity(activity));
  }

  Future<void> deleteActivity(String id) async {
    _activities.removeWhere((a) => a.id == id);
    notifyListeners();
    await _sync(() => _repo.deleteActivity(id));
  }

  // ---------------- Expenses ----------------

  List<Expense> expensesOf(String tripId) =>
      _expenses.where((e) => e.tripId == tripId).toList()..sort((a, b) {
        final d = a.date.compareTo(b.date);
        return d != 0 ? d : a.minutes.compareTo(b.minutes);
      });

  double spentThb(Trip trip) => expensesOf(
    trip.id,
  ).fold(0, (sum, e) => sum + e.amount * rateToThb(trip.currency));

  Future<void> saveExpense({
    String? id,
    required String tripId,
    required DateTime date,
    required int minutes,
    required String title,
    required double amount,
    required ExpenseCategory category,
    required PaymentMethod payment,
  }) async {
    final expense = Expense(
      id: id ?? _newId(),
      tripId: tripId,
      date: dateOnly(date),
      minutes: minutes,
      title: title,
      amount: amount,
      category: category,
      payment: payment,
    );
    _expenses = [..._expenses.where((e) => e.id != expense.id), expense];
    notifyListeners();
    await _sync(() => _repo.upsertExpense(expense));
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
    await _sync(() => _repo.deleteExpense(id));
  }

  // ---------------- Exchange rate ----------------

  /// THB per 1 unit of [currency]: live if fetched, cached, or fallback.
  double rateToThb(String currency) =>
      _rates[currency] ?? ExchangeService.fallback[currency] ?? 1;

  Future<void> refreshRate(String currency) async {
    if (!_ratesRequested.add(currency)) return;
    final value = await _exchange.fetchToThb(currency);
    if (value == null || value == _rates[currency]) return;
    _rates[currency] = value;
    notifyListeners();
    await _prefs.saveRates(_rates);
  }

  // ---------------- Weather ----------------

  Weather? weatherFor(String city) => _weatherCache[city];
  bool isWeatherLoading(String city) => _weatherLoading.contains(city);

  Future<void> refreshWeather(String city) async {
    if (_weatherLoading.contains(city) || _weatherCache.containsKey(city)) {
      return;
    }
    _weatherLoading.add(city);
    notifyListeners();
    final w = await _weather.fetch(city);
    _weatherLoading.remove(city);
    _weatherCache[city] = w;
    notifyListeners();
  }

  static final _random = Random.secure();

  /// Unique across devices: timestamp plus random suffix.
  /// Random part uses two 30-bit draws: on web, ints are JS numbers and
  /// `1 << 32` wraps to 0, which would make nextInt throw.
  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${_random.nextInt(1 << 30).toRadixString(36).padLeft(6, '0')}'
      '${_random.nextInt(1 << 30).toRadixString(36).padLeft(6, '0')}';
}

/// Exposes [AppState] to the widget tree and rebuilds dependents on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Reads without subscribing — use in callbacks.
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
