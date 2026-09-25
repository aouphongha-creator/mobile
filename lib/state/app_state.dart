import 'package:flutter/widgets.dart';

import '../app/app_info.dart';
import '../models/models.dart';
import '../services/remote.dart';
import '../services/storage.dart';
import '../utils/format.dart';
import 'seed.dart';

class AppState extends ChangeNotifier {
  AppState({
    Storage? storage,
    WeatherService? weather,
    ExchangeService? exchange,
    DateTime Function()? clock,
  })  : _storage = storage ?? Storage(),
        _weather = weather ?? WeatherService(apiKey: openWeatherApiKey),
        _exchange = exchange ?? ExchangeService(),
        _clock = clock ?? DateTime.now;

  final Storage _storage;
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

  DateTime get now => _clock();

  Future<void> load() async {
    if (!await _storage.isSeeded()) {
      final seed = buildSeed(now);
      await _storage.saveTrips(seed.trips);
      await _storage.saveActivities(seed.activities);
      await _storage.saveExpenses(seed.expenses);
      await _storage.markSeeded();
    }
    _trips = await _storage.loadTrips();
    _activities = await _storage.loadActivities();
    _expenses = await _storage.loadExpenses();
    _rates.addAll(await _storage.loadRates());
    loaded = true;
    notifyListeners();
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
  Trip? get selectedTrip => tripById(_selectedTripId) ?? (trips.isEmpty ? null : trips.first);

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
    await _storage.saveTrips(_trips);
    return trip;
  }

  Future<void> deleteTrip(String id) async {
    _trips.removeWhere((t) => t.id == id);
    _activities.removeWhere((a) => a.tripId == id);
    _expenses.removeWhere((e) => e.tripId == id);
    if (_selectedTripId == id) _selectedTripId = null;
    notifyListeners();
    await Future.wait([
      _storage.saveTrips(_trips),
      _storage.saveActivities(_activities),
      _storage.saveExpenses(_expenses),
    ]);
  }

  // ---------------- Activities ----------------

  List<Activity> activitiesOn(String tripId, DateTime day) => _activities
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
    if (i >= 0) {
      _activities[i] = _activities[i].copyWith(minutes: minutes, name: name, note: note);
    } else {
      _activities.add(Activity(
        id: _newId(),
        tripId: tripId,
        date: dateOnly(date),
        minutes: minutes,
        name: name,
        note: note,
      ));
    }
    notifyListeners();
    await _storage.saveActivities(_activities);
  }

  Future<void> setActivityImage(String id, String path) async {
    final i = _activities.indexWhere((a) => a.id == id);
    if (i < 0) return;
    _activities[i] = _activities[i].copyWith(imagePath: path);
    notifyListeners();
    await _storage.saveActivities(_activities);
  }

  Future<void> deleteActivity(String id) async {
    _activities.removeWhere((a) => a.id == id);
    notifyListeners();
    await _storage.saveActivities(_activities);
  }

  // ---------------- Expenses ----------------

  List<Expense> expensesOf(String tripId) =>
      _expenses.where((e) => e.tripId == tripId).toList()
        ..sort((a, b) {
          final d = a.date.compareTo(b.date);
          return d != 0 ? d : a.minutes.compareTo(b.minutes);
        });

  double spentThb(Trip trip) =>
      expensesOf(trip.id).fold(0, (sum, e) => sum + e.amount * rateToThb(trip.currency));

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
    await _storage.saveExpenses(_expenses);
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
    await _storage.saveExpenses(_expenses);
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
    await _storage.saveRates(_rates);
  }

  // ---------------- Weather ----------------

  Weather? weatherFor(String city) => _weatherCache[city];
  bool isWeatherLoading(String city) => _weatherLoading.contains(city);

  Future<void> refreshWeather(String city) async {
    if (_weatherLoading.contains(city) || _weatherCache.containsKey(city)) return;
    _weatherLoading.add(city);
    notifyListeners();
    final w = await _weather.fetch(city);
    _weatherLoading.remove(city);
    _weatherCache[city] = w;
    notifyListeners();
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
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
