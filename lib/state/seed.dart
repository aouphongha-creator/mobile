import '../models/models.dart';
import '../utils/format.dart';

/// Sample data shown on first launch, dated relative to today so the
/// statuses match the design (one ongoing, two planned, one done).
({List<Trip> trips, List<Activity> activities, List<Expense> expenses}) buildSeed(
    DateTime now) {
  final today = dateOnly(now);
  DateTime day(int offset) => DateTime(today.year, today.month, today.day + offset);

  final trips = [
    Trip(
      id: 't1',
      name: 'ทริปเที่ยวโตเกียว กับครอบครัว',
      destination: 'โตเกียว, ญี่ปุ่น',
      start: day(0),
      end: day(5),
      budget: 40000,
      currency: 'JPY',
    ),
    Trip(
      id: 't2',
      name: 'เที่ยวเชียงใหม่',
      destination: 'เชียงใหม่, ไทย',
      start: day(37),
      end: day(39),
      budget: 8000,
      currency: 'THB',
    ),
    Trip(
      id: 't3',
      name: 'ทริปซัปโปโร',
      destination: 'ซัปโปโร, ญี่ปุ่น',
      start: day(98),
      end: day(102),
      budget: 30000,
      currency: 'JPY',
    ),
    Trip(
      id: 't4',
      name: 'พักผ่อนภูเก็ต',
      destination: 'ภูเก็ต, ไทย',
      start: day(-160),
      end: day(-158),
      budget: 5000,
      currency: 'THB',
    ),
  ];

  final activities = [
    Activity(id: 'a1', tripId: 't1', date: day(0), minutes: 9 * 60,
        name: 'วัดเซ็นโซจิ', note: 'ถ่ายรูปประตูคามินาริมง'),
    Activity(id: 'a2', tripId: 't1', date: day(0), minutes: 12 * 60,
        name: 'ชิบูย่าครอสซิ่ง', note: 'ทานอาหารกลางวัน'),
    Activity(id: 'a3', tripId: 't1', date: day(0), minutes: 15 * 60, name: 'สวนอุเอโนะ'),
    Activity(id: 'a4', tripId: 't1', date: day(0), minutes: 18 * 60, name: 'ย่านชินจูกุ'),
    Activity(id: 'a5', tripId: 't1', date: day(1), minutes: 10 * 60,
        name: 'โตเกียวทาวเวอร์', note: 'ชมวิวบนจุดชมวิว'),
    Activity(id: 'a6', tripId: 't1', date: day(2), minutes: 9 * 60 + 30,
        name: 'ภูเขาไฟฟูจิ', note: 'ทัวร์ 1 วัน'),
  ];

  final expenses = [
    Expense(id: 'e1', tripId: 't1', date: day(0), minutes: 12 * 60 + 30,
        title: 'ค่าอาหารมื้อเที่ยง', amount: 3500,
        category: ExpenseCategory.food, payment: PaymentMethod.cash),
    Expense(id: 'e2', tripId: 't1', date: day(0), minutes: 9 * 60 + 35,
        title: 'ตั๋ว Keisei Skyliner', amount: 2570,
        category: ExpenseCategory.transport, payment: PaymentMethod.card),
    Expense(id: 'e3', tripId: 't1', date: day(0), minutes: 17 * 60,
        title: 'ค่าชุดกิโมโน', amount: 5000,
        category: ExpenseCategory.shopping, payment: PaymentMethod.cash),
    Expense(id: 'e4', tripId: 't1', date: day(1), minutes: 12 * 60 + 30,
        title: 'ค่าที่พัก Shinjuku Hotel', amount: 3500,
        category: ExpenseCategory.hotel, payment: PaymentMethod.transfer),
    Expense(id: 'e5', tripId: 't1', date: day(1), minutes: 14 * 60 + 30,
        title: 'ขนมหวานคาเฟ่ชิบูย่า', amount: 2000,
        category: ExpenseCategory.food, payment: PaymentMethod.icCard),
    Expense(id: 'e6', tripId: 't1', date: day(1), minutes: 19 * 60,
        title: 'ราเมง & ของฝากเครื่องดื่ม', amount: 1200,
        category: ExpenseCategory.food, payment: PaymentMethod.cash),
    Expense(id: 'e7', tripId: 't4', date: day(-160), minutes: 13 * 60,
        title: 'อาหารทะเล', amount: 1000,
        category: ExpenseCategory.food, payment: PaymentMethod.cash),
  ];

  return (trips: trips, activities: activities, expenses: expenses);
}
