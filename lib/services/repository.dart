import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

typedef AppData = ({
  List<Trip> trips,
  List<Activity> activities,
  List<Expense> expenses,
});

/// Where trips, activities and expenses are stored.
abstract class Repository {
  /// Connects/authenticates; called once before [loadAll].
  Future<void> init() async {}

  Future<AppData> loadAll();

  Future<void> upsertTrip(Trip trip);

  /// Also removes the trip's activities and expenses.
  Future<void> deleteTrip(String id);

  Future<void> upsertActivity(Activity activity);
  Future<void> deleteActivity(String id);

  Future<void> upsertExpense(Expense expense);
  Future<void> deleteExpense(String id);

  /// Bulk insert used for first-launch sample data.
  Future<void> insertAll(AppData data);
}

/// On-device storage in shared_preferences (works offline, one device).
class LocalRepository extends Repository {
  static const _kTrips = 'trips';
  static const _kActivities = 'activities';
  static const _kExpenses = 'expenses';

  List<Trip> _trips = [];
  List<Activity> _activities = [];
  List<Expense> _expenses = [];

  @override
  Future<AppData> loadAll() async {
    final p = await SharedPreferences.getInstance();
    List<T> read<T>(String key, T Function(Map<String, dynamic>) f) {
      final raw = p.getString(key);
      if (raw == null) return [];
      return (jsonDecode(raw) as List)
          .map((e) => f(e as Map<String, dynamic>))
          .toList();
    }

    _trips = read(_kTrips, Trip.fromJson);
    _activities = read(_kActivities, Activity.fromJson);
    _expenses = read(_kExpenses, Expense.fromJson);
    return (
      trips: [..._trips],
      activities: [..._activities],
      expenses: [..._expenses],
    );
  }

  @override
  Future<void> upsertTrip(Trip trip) {
    _trips = [..._trips.where((t) => t.id != trip.id), trip];
    return _save(_kTrips, _trips.map((e) => e.toJson()));
  }

  @override
  Future<void> deleteTrip(String id) async {
    _trips.removeWhere((t) => t.id == id);
    _activities.removeWhere((a) => a.tripId == id);
    _expenses.removeWhere((e) => e.tripId == id);
    await Future.wait([
      _save(_kTrips, _trips.map((e) => e.toJson())),
      _save(_kActivities, _activities.map((e) => e.toJson())),
      _save(_kExpenses, _expenses.map((e) => e.toJson())),
    ]);
  }

  @override
  Future<void> upsertActivity(Activity activity) {
    _activities = [..._activities.where((a) => a.id != activity.id), activity];
    return _save(_kActivities, _activities.map((e) => e.toJson()));
  }

  @override
  Future<void> deleteActivity(String id) {
    _activities.removeWhere((a) => a.id == id);
    return _save(_kActivities, _activities.map((e) => e.toJson()));
  }

  @override
  Future<void> upsertExpense(Expense expense) {
    _expenses = [..._expenses.where((e) => e.id != expense.id), expense];
    return _save(_kExpenses, _expenses.map((e) => e.toJson()));
  }

  @override
  Future<void> deleteExpense(String id) {
    _expenses.removeWhere((e) => e.id == id);
    return _save(_kExpenses, _expenses.map((e) => e.toJson()));
  }

  @override
  Future<void> insertAll(AppData data) async {
    _trips = [..._trips, ...data.trips];
    _activities = [..._activities, ...data.activities];
    _expenses = [..._expenses, ...data.expenses];
    await Future.wait([
      _save(_kTrips, _trips.map((e) => e.toJson())),
      _save(_kActivities, _activities.map((e) => e.toJson())),
      _save(_kExpenses, _expenses.map((e) => e.toJson())),
    ]);
  }

  Future<void> _save(String key, Iterable<Map<String, dynamic>> items) async =>
      (await SharedPreferences.getInstance()).setString(
        key,
        jsonEncode(items.toList()),
      );
}

/// Small device-local settings that never go to the server.
class Prefs {
  static const _kSeeded = 'seeded';
  static const _kRates = 'rates';

  Future<bool> isSeeded() async =>
      (await SharedPreferences.getInstance()).getBool(_kSeeded) ?? false;

  Future<void> markSeeded() async =>
      (await SharedPreferences.getInstance()).setBool(_kSeeded, true);

  /// Cached currency → THB rates from the last successful fetch.
  Future<Map<String, double>> loadRates() async {
    final raw = (await SharedPreferences.getInstance()).getString(_kRates);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
  }

  Future<void> saveRates(Map<String, double> rates) async =>
      (await SharedPreferences.getInstance()).setString(
        _kRates,
        jsonEncode(rates),
      );
}
