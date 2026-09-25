import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'repository.dart';

/// Stores data in Supabase tables (see supabase/schema.sql).
///
/// Each install signs in anonymously; Row Level Security limits every
/// row to its owner, so devices only ever see their own trips.
class SupabaseRepository extends Repository {
  SupabaseRepository(this._db);

  final SupabaseClient _db;

  @override
  Future<void> init() async {
    if (_db.auth.currentSession == null) {
      await _db.auth.signInAnonymously();
    }
  }

  @override
  Future<AppData> loadAll() async {
    final results = await Future.wait([
      _db.from('trips').select(),
      _db.from('activities').select(),
      _db.from('expenses').select(),
    ]);
    return (
      trips: results[0].map(_tripFromRow).toList(),
      activities: results[1].map(_activityFromRow).toList(),
      expenses: results[2].map(_expenseFromRow).toList(),
    );
  }

  @override
  Future<void> upsertTrip(Trip trip) =>
      _write(() => _db.from('trips').upsert(_tripToRow(trip)));

  /// Activities and expenses go with it via ON DELETE CASCADE.
  @override
  Future<void> deleteTrip(String id) =>
      _write(() => _db.from('trips').delete().eq('id', id));

  @override
  Future<void> upsertActivity(Activity a) =>
      _write(() => _db.from('activities').upsert(_activityToRow(a)));

  @override
  Future<void> deleteActivity(String id) =>
      _write(() => _db.from('activities').delete().eq('id', id));

  @override
  Future<void> upsertExpense(Expense e) =>
      _write(() => _db.from('expenses').upsert(_expenseToRow(e)));

  @override
  Future<void> deleteExpense(String id) =>
      _write(() => _db.from('expenses').delete().eq('id', id));

  /// Signs in first if the startup sign-in failed (e.g. offline), so a
  /// write never goes out without a user and gets rejected by RLS.
  Future<void> _write(Future<void> Function() op) async {
    await init();
    await op();
  }

  @override
  Future<void> insertAll(AppData data) async {
    // Trips first: the other tables reference them.
    if (data.trips.isNotEmpty) {
      await _db.from('trips').insert(data.trips.map(_tripToRow).toList());
    }
    await Future.wait([
      if (data.activities.isNotEmpty)
        _db
            .from('activities')
            .insert(data.activities.map(_activityToRow).toList()),
      if (data.expenses.isNotEmpty)
        _db.from('expenses').insert(data.expenses.map(_expenseToRow).toList()),
    ]);
  }

  // ---- Row mapping (snake_case columns, DATE columns as yyyy-mm-dd) ----

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Map<String, dynamic> _tripToRow(Trip t) => {
    'id': t.id,
    'name': t.name,
    'destination': t.destination,
    'start_date': _date(t.start),
    'end_date': _date(t.end),
    'budget': t.budget,
    'currency': t.currency,
  };

  static Trip _tripFromRow(Map<String, dynamic> r) => Trip(
    id: r['id'] as String,
    name: r['name'] as String,
    destination: r['destination'] as String,
    start: DateTime.parse(r['start_date'] as String),
    end: DateTime.parse(r['end_date'] as String),
    budget: (r['budget'] as num).toDouble(),
    currency: r['currency'] as String,
  );

  static Map<String, dynamic> _activityToRow(Activity a) => {
    'id': a.id,
    'trip_id': a.tripId,
    'date': _date(a.date),
    'minutes': a.minutes,
    'name': a.name,
    'note': a.note,
    'image_path': a.imagePath,
  };

  static Activity _activityFromRow(Map<String, dynamic> r) => Activity(
    id: r['id'] as String,
    tripId: r['trip_id'] as String,
    date: DateTime.parse(r['date'] as String),
    minutes: r['minutes'] as int,
    name: r['name'] as String,
    note: (r['note'] as String?) ?? '',
    imagePath: r['image_path'] as String?,
  );

  static Map<String, dynamic> _expenseToRow(Expense e) => {
    'id': e.id,
    'trip_id': e.tripId,
    'date': _date(e.date),
    'minutes': e.minutes,
    'title': e.title,
    'amount': e.amount,
    'category': e.category.name,
    'payment': e.payment.name,
  };

  static Expense _expenseFromRow(Map<String, dynamic> r) => Expense(
    id: r['id'] as String,
    tripId: r['trip_id'] as String,
    date: DateTime.parse(r['date'] as String),
    minutes: r['minutes'] as int,
    title: r['title'] as String,
    amount: (r['amount'] as num).toDouble(),
    category: ExpenseCategory.values.byName(r['category'] as String),
    payment: PaymentMethod.values.byName(r['payment'] as String),
  );
}
