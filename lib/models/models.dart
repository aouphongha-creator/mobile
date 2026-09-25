import '../utils/format.dart';

enum TripStatus { ongoing, planned, done }

extension TripStatusLabel on TripStatus {
  String get label => switch (this) {
    TripStatus.ongoing => 'กำลังเดินทาง',
    TripStatus.planned => 'วางแผน',
    TripStatus.done => 'จบแล้ว',
  };
}

class Trip {
  const Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.start,
    required this.end,
    required this.budget,
    required this.currency,
  });

  final String id;
  final String name;

  /// "โตเกียว, ญี่ปุ่น" — the first part is used for weather lookup.
  final String destination;
  final DateTime start;
  final DateTime end;

  /// Total budget in THB.
  final double budget;

  /// Local currency code at the destination, e.g. JPY.
  final String currency;

  String get city => destination.split(',').first.trim();

  List<DateTime> get days => [
    for (
      var d = dateOnly(start);
      !d.isAfter(dateOnly(end));
      d = DateTime(d.year, d.month, d.day + 1)
    )
      d,
  ];

  TripStatus statusOn(DateTime now) {
    final today = dateOnly(now);
    if (today.isBefore(dateOnly(start))) return TripStatus.planned;
    if (today.isAfter(dateOnly(end))) return TripStatus.done;
    return TripStatus.ongoing;
  }

  Trip copyWith({
    String? name,
    String? destination,
    DateTime? start,
    DateTime? end,
    double? budget,
    String? currency,
  }) => Trip(
    id: id,
    name: name ?? this.name,
    destination: destination ?? this.destination,
    start: start ?? this.start,
    end: end ?? this.end,
    budget: budget ?? this.budget,
    currency: currency ?? this.currency,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'destination': destination,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'budget': budget,
    'currency': currency,
  };

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
    id: j['id'] as String,
    name: j['name'] as String,
    destination: j['destination'] as String,
    start: DateTime.parse(j['start'] as String),
    end: DateTime.parse(j['end'] as String),
    budget: (j['budget'] as num).toDouble(),
    currency: j['currency'] as String,
  );
}

/// A place to visit on a given day of a trip.
class Activity {
  const Activity({
    required this.id,
    required this.tripId,
    required this.date,
    required this.minutes,
    required this.name,
    this.note = '',
    this.imagePath,
  });

  final String id;
  final String tripId;
  final DateTime date;

  /// Start time as minutes since midnight.
  final int minutes;
  final String name;
  final String note;
  final String? imagePath;

  Activity copyWith({
    int? minutes,
    String? name,
    String? note,
    String? imagePath,
  }) => Activity(
    id: id,
    tripId: tripId,
    date: date,
    minutes: minutes ?? this.minutes,
    name: name ?? this.name,
    note: note ?? this.note,
    imagePath: imagePath ?? this.imagePath,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tripId': tripId,
    'date': date.toIso8601String(),
    'minutes': minutes,
    'name': name,
    'note': note,
    'imagePath': imagePath,
  };

  factory Activity.fromJson(Map<String, dynamic> j) => Activity(
    id: j['id'] as String,
    tripId: j['tripId'] as String,
    date: DateTime.parse(j['date'] as String),
    minutes: j['minutes'] as int,
    name: j['name'] as String,
    note: (j['note'] as String?) ?? '',
    imagePath: j['imagePath'] as String?,
  );
}

enum ExpenseCategory { food, transport, hotel, shopping, activity, other }

extension ExpenseCategoryLabel on ExpenseCategory {
  String get label => switch (this) {
    ExpenseCategory.food => 'อาหาร',
    ExpenseCategory.transport => 'เดินทาง',
    ExpenseCategory.hotel => 'ที่พัก',
    ExpenseCategory.shopping => 'ช้อปปิ้ง',
    ExpenseCategory.activity => 'กิจกรรม',
    ExpenseCategory.other => 'อื่นๆ',
  };
}

enum PaymentMethod { cash, card, transfer, icCard }

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.cash => 'เงินสด',
    PaymentMethod.card => 'บัตรเครดิต',
    PaymentMethod.transfer => 'โอนเงิน',
    PaymentMethod.icCard => 'IC Card',
  };
}

class Expense {
  const Expense({
    required this.id,
    required this.tripId,
    required this.date,
    required this.minutes,
    required this.title,
    required this.amount,
    required this.category,
    required this.payment,
  });

  final String id;
  final String tripId;
  final DateTime date;
  final int minutes;
  final String title;

  /// Amount in the trip's local currency.
  final double amount;
  final ExpenseCategory category;
  final PaymentMethod payment;

  Map<String, dynamic> toJson() => {
    'id': id,
    'tripId': tripId,
    'date': date.toIso8601String(),
    'minutes': minutes,
    'title': title,
    'amount': amount,
    'category': category.name,
    'payment': payment.name,
  };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
    id: j['id'] as String,
    tripId: j['tripId'] as String,
    date: DateTime.parse(j['date'] as String),
    minutes: j['minutes'] as int,
    title: j['title'] as String,
    amount: (j['amount'] as num).toDouble(),
    category: ExpenseCategory.values.byName(j['category'] as String),
    payment: PaymentMethod.values.byName(j['payment'] as String),
  );
}
