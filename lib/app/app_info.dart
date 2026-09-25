/// Content for the "JORNY OG" info page. Edit these values to match the
/// course and team details.
class AppInfo {
  AppInfo._();

  static const appName = 'JORNY OG';
  static const courseName = 'Mobile Application Design and Development';
  static const courseCode = '02739343';
  static const section = '820';

  static const members = [
    (name: 'ธัญวรรณ บูรณะกิจ', studentId: '6721652251', number: '1'),
    (name: 'ภัทรชนน พงษ์หา', studentId: '6721652498', number: '2'),
  ];

  static const apis = [
    (name: 'OpenWeatherMap API', use: 'สภาพอากาศปัจจุบันและพยากรณ์ล่วงหน้า'),
    (name: 'Open-Meteo API', use: 'สภาพอากาศสำรอง (เมื่อไม่ได้ใส่ API key)'),
    (name: 'ExchangeRate-API', use: 'อัตราแลกเปลี่ยนเงินตราเป็นบาท'),
    (name: 'Supabase', use: 'ฐานข้อมูลทริป แผนรายวัน และค่าใช้จ่าย'),
  ];
}

/// OpenWeatherMap key, passed at build time:
///   flutter run --dart-define=OWM_API_KEY=your_key
const openWeatherApiKey = String.fromEnvironment('OWM_API_KEY');
