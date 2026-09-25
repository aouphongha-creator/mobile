import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

class DailyTemp {
  const DailyTemp(this.date, this.maxTemp);

  final DateTime date;
  final double maxTemp;
}

class Weather {
  const Weather({
    required this.city,
    required this.temp,
    required this.description,
    required this.next,
  });

  final String city;
  final double temp;
  final String description;
  final List<DailyTemp> next;
}

/// Weather from OpenWeatherMap when [apiKey] is set, otherwise from
/// Open-Meteo (free, no key) so the widget still works out of the box.
class WeatherService {
  WeatherService({http.Client? client, this.apiKey = ''})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String apiKey;

  Future<Weather?> fetch(String city) async {
    if (apiKey.isNotEmpty) {
      final w = await _fetchOpenWeather(city);
      if (w != null) return w;
    }
    return _fetchOpenMeteo(city);
  }

  Future<Weather?> _fetchOpenWeather(String city) async {
    try {
      final geo = await _getJsonList(Uri.https('api.openweathermap.org', '/geo/1.0/direct',
          {'q': city, 'limit': '1', 'appid': apiKey}));
      if (geo.isEmpty) return null;
      final place = geo.first as Map<String, dynamic>;
      final coords = {
        'lat': '${place['lat']}',
        'lon': '${place['lon']}',
        'units': 'metric',
        'lang': 'th',
        'appid': apiKey,
      };

      final current =
          await _getJson(Uri.https('api.openweathermap.org', '/data/2.5/weather', coords));
      final forecast =
          await _getJson(Uri.https('api.openweathermap.org', '/data/2.5/forecast', coords));

      // Forecast comes in 3-hour slots; keep the max temperature per day.
      final today = DateTime.now();
      final maxByDay = <DateTime, double>{};
      for (final slot in (forecast['list'] as List).cast<Map<String, dynamic>>()) {
        final t = DateTime.fromMillisecondsSinceEpoch((slot['dt'] as int) * 1000);
        final day = DateTime(t.year, t.month, t.day);
        if (!day.isAfter(DateTime(today.year, today.month, today.day))) continue;
        final temp = ((slot['main'] as Map)['temp_max'] as num).toDouble();
        maxByDay[day] = max(maxByDay[day] ?? temp, temp);
      }
      final days = maxByDay.keys.toList()..sort();

      final weatherList = (current['weather'] as List).cast<Map<String, dynamic>>();
      return Weather(
        city: city,
        temp: ((current['main'] as Map)['temp'] as num).toDouble(),
        description: weatherList.isEmpty ? '-' : weatherList.first['description'] as String,
        next: [for (final d in days.take(3)) DailyTemp(d, maxByDay[d]!)],
      );
    } catch (_) {
      return null;
    }
  }

  Future<Weather?> _fetchOpenMeteo(String city) async {
    try {
      final geo = await _getJson(Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': city,
        'count': '1',
        'language': 'th',
      }));
      final results = geo['results'] as List?;
      if (results == null || results.isEmpty) return null;
      final place = results.first as Map<String, dynamic>;

      final data = await _getJson(Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '${place['latitude']}',
        'longitude': '${place['longitude']}',
        'current': 'temperature_2m,weather_code',
        'daily': 'temperature_2m_max',
        'timezone': 'auto',
        'forecast_days': '4',
      }));
      final current = data['current'] as Map<String, dynamic>;
      final daily = data['daily'] as Map<String, dynamic>;
      final dates = (daily['time'] as List).cast<String>();
      final temps = (daily['temperature_2m_max'] as List).cast<num>();

      return Weather(
        city: city,
        temp: (current['temperature_2m'] as num).toDouble(),
        description: describe(current['weather_code'] as int),
        next: [
          for (var i = 1; i < dates.length; i++)
            DailyTemp(DateTime.parse(dates[i]), temps[i].toDouble()),
        ],
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final res = await _client.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  Future<List<dynamic>> _getJsonList(Uri uri) async {
    final res = await _client.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
  }

  /// WMO weather code → Thai description.
  static String describe(int code) {
    if (code == 0) return 'แดดจัด';
    if (code <= 3) return 'มีเมฆบางส่วน';
    if (code <= 48) return 'มีหมอก';
    if (code <= 67) return 'ฝนตก';
    if (code <= 77) return 'หิมะตก';
    if (code <= 82) return 'ฝนตกหนัก';
    return 'พายุฝนฟ้าคะนอง';
  }
}

/// Exchange rates from ExchangeRate-API's open endpoint (no key needed).
class ExchangeService {
  ExchangeService([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  /// Offline fallback: approximate THB per 1 unit of currency.
  static const fallback = <String, double>{
    'THB': 1,
    'JPY': 0.24,
    'USD': 36.5,
    'EUR': 39.5,
    'GBP': 46.0,
    'KRW': 0.026,
    'CNY': 5.0,
    'TWD': 1.12,
    'HKD': 4.7,
    'SGD': 27.0,
    'VND': 0.0014,
    'AUD': 24.0,
  };

  static List<String> get currencies => fallback.keys.toList();

  /// THB per 1 unit of [currency], or null when offline.
  Future<double?> fetchToThb(String currency) async {
    if (currency == 'THB') return 1;
    try {
      final res = await _client
          .get(Uri.https('open.er-api.com', '/v6/latest/$currency'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return ((body['rates'] as Map<String, dynamic>)['THB'] as num).toDouble();
    } catch (_) {
      return null;
    }
  }
}
