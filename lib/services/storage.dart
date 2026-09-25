import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Local persistence. Swap for an API-backed implementation later
/// without touching the UI.
class Storage {
  static const _kTrips = 'trips';
  static const _kActivities = 'activities';
  static const _kExpenses = 'expenses';
  static const _kSeeded = 'seeded';
  static const _kRates = 'rates';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> isSeeded() async => (await _prefs).getBool(_kSeeded) ?? false;
  Future<void> markSeeded() async => (await _prefs).setBool(_kSeeded, true);

  Future<List<Trip>> loadTrips() => _loadList(_kTrips, Trip.fromJson);
  Future<List<Activity>> loadActivities() => _loadList(_kActivities, Activity.fromJson);
  Future<List<Expense>> loadExpenses() => _loadList(_kExpenses, Expense.fromJson);

  Future<void> saveTrips(List<Trip> v) => _saveList(_kTrips, v.map((e) => e.toJson()));
  Future<void> saveActivities(List<Activity> v) =>
      _saveList(_kActivities, v.map((e) => e.toJson()));
  Future<void> saveExpenses(List<Expense> v) =>
      _saveList(_kExpenses, v.map((e) => e.toJson()));

  /// Cached currency → THB rates from the last successful fetch.
  Future<Map<String, double>> loadRates() async {
    final raw = (await _prefs).getString(_kRates);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  Future<void> saveRates(Map<String, double> rates) async =>
      (await _prefs).setString(_kRates, jsonEncode(rates));

  Future<List<T>> _loadList<T>(String key, T Function(Map<String, dynamic>) f) async {
    final raw = (await _prefs).getString(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => f(e as Map<String, dynamic>)).toList();
  }

  Future<void> _saveList(String key, Iterable<Map<String, dynamic>> items) async =>
      (await _prefs).setString(key, jsonEncode(items.toList()));
}
