import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/main.dart';
import 'package:mobile/models/models.dart';
import 'package:mobile/services/remote.dart';
import 'package:mobile/state/app_state.dart';

final _offline = MockClient((_) async => http.Response('offline', 503));
final _fixedNow = DateTime(2026, 9, 25, 10);

AppState _state() => AppState(
      weather: WeatherService(client: _offline),
      exchange: ExchangeService(_offline),
      clock: () => _fixedNow,
    );

Future<void> _pumpApp(WidgetTester tester, AppState state) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(JournyApp(state: state, splashDuration: Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('home lists seeded trips with status badges', (tester) async {
    await _pumpApp(tester, _state());

    expect(find.text('ทริปของฉัน'), findsOneWidget);
    expect(find.text('ทริปเที่ยวโตเกียว กับครอบครัว'), findsOneWidget);
    expect(find.text('กำลังเดินทาง'), findsOneWidget);
    expect(find.text('วางแผน'), findsNWidgets(2));
    expect(find.text('จบแล้ว'), findsOneWidget);
  });

  testWidgets('tapping a trip opens its plan on the Detail tab', (tester) async {
    await _pumpApp(tester, _state());

    await tester.tap(find.text('ทริปเที่ยวโตเกียว กับครอบครัว'));
    await tester.pumpAndSettle();

    expect(find.text('แผนการเดินทาง'), findsOneWidget);
    expect(find.text('โตเกียว, ญี่ปุ่น'), findsOneWidget);
    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('วัดเซ็นโซจิ'), findsOneWidget);
    expect(find.text('1 JPY = 0.24 THB'), findsOneWidget);
  });

  testWidgets('edit expands the trip card into an inline form', (tester) async {
    await _pumpApp(tester, _state());

    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pumpAndSettle();

    expect(find.text('บันทึก'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'ทริปเที่ยวโตเกียว กับครอบครัว'),
        findsOneWidget);
  });

  test('trip status follows the dates', () {
    final trip = Trip(
      id: 'x',
      name: 'x',
      destination: 'a, b',
      start: DateTime(2026, 9, 20),
      end: DateTime(2026, 9, 22),
      budget: 1,
      currency: 'THB',
    );
    expect(trip.statusOn(DateTime(2026, 9, 19)), TripStatus.planned);
    expect(trip.statusOn(DateTime(2026, 9, 21, 23)), TripStatus.ongoing);
    expect(trip.statusOn(DateTime(2026, 9, 23)), TripStatus.done);
    expect(trip.days, hasLength(3));
  });

  test('CRUD across trips, activities and expenses persists', () async {
    final state = _state();
    await state.load();

    final trip = await state.saveTrip(
      name: 'ทดสอบ',
      destination: 'โซล, เกาหลีใต้',
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 3),
      budget: 20000,
      currency: 'JPY',
    );
    await state.saveActivity(
        tripId: trip.id, date: DateTime(2026, 10, 1), minutes: 600, name: 'พระราชวัง');
    await state.saveExpense(
      tripId: trip.id,
      date: DateTime(2026, 10, 1),
      minutes: 700,
      title: 'ข้าว',
      amount: 1000,
      category: ExpenseCategory.food,
      payment: PaymentMethod.cash,
    );
    expect(state.spentThb(trip), closeTo(240, 0.001)); // fallback 0.24 THB/JPY

    final reloaded = _state();
    await reloaded.load();
    expect(reloaded.tripById(trip.id)?.name, 'ทดสอบ');
    expect(reloaded.activitiesOn(trip.id, DateTime(2026, 10, 1)), hasLength(1));
    expect(reloaded.expensesOf(trip.id), hasLength(1));

    await reloaded.deleteTrip(trip.id);
    expect(reloaded.tripById(trip.id), isNull);
    expect(reloaded.expensesOf(trip.id), isEmpty);
    expect(reloaded.activitiesOn(trip.id, DateTime(2026, 10, 1)), isEmpty);
  });

  test('weather falls back to Open-Meteo and parses the forecast', () async {
    final client = MockClient((req) async {
      if (req.url.host.startsWith('geocoding')) {
        return http.Response(
            jsonEncode({
              'results': [
                {'latitude': 35.6, 'longitude': 139.7}
              ]
            }),
            200);
      }
      return http.Response(
          jsonEncode({
            'current': {'temperature_2m': 29.4, 'weather_code': 0},
            'daily': {
              'time': ['2026-09-25', '2026-09-26', '2026-09-27', '2026-09-28'],
              'temperature_2m_max': [30, 29, 24, 30],
            },
          }),
          200);
    });
    final w = await WeatherService(client: client).fetch('โตเกียว');
    expect(w?.temp.round(), 29);
    expect(w?.description, 'แดดจัด');
    expect(w?.next.map((d) => d.maxTemp), [29, 24, 30]);
  });
}
