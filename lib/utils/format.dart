const _thaiMonths = [
  'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
  'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
];

const _thaiWeekdaysShort = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];

const _enMonthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int buddhistYear(DateTime d) => d.year + 543;

/// 10 กันยายน 2569
String thaiDate(DateTime d) => '${d.day} ${_thaiMonths[d.month - 1]} ${buddhistYear(d)}';

/// 10 กันยายน 2569 - 15 กันยายน 2569
String thaiRange(DateTime a, DateTime b) => '${thaiDate(a)} - ${thaiDate(b)}';

/// 01/01/2570
String thaiNumericDate(DateTime d) =>
    '${_two(d.day)}/${_two(d.month)}/${buddhistYear(d)}';

/// ศ. 11
String thaiWeekdayDay(DateTime d) => '${_thaiWeekdaysShort[d.weekday - 1]} ${d.day}';

/// Oct 10
String enShortDate(DateTime d) => '${_enMonthsShort[d.month - 1]} ${d.day}';

/// 09:00
String hhmm(int minutes) => '${_two(minutes ~/ 60)}:${_two(minutes % 60)}';

/// Parses "9:00", "09.00" or "0900" into minutes since midnight.
int? parseTime(String input) {
  final m = RegExp(r'^(\d{1,2})[:.]?(\d{2})$').firstMatch(input.trim());
  if (m == null) return null;
  final h = int.parse(m.group(1)!), min = int.parse(m.group(2)!);
  if (h > 23 || min > 59) return null;
  return h * 60 + min;
}

/// 15,400 — rounds to whole numbers.
String money(num value) {
  final s = value.round().abs().toString();
  final buf = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// 0.24 / 36.5 / 0.026 — keeps small rates readable.
String rate(double value) =>
    value >= 0.1 ? value.toStringAsFixed(2) : value.toStringAsFixed(4);

String _two(int n) => n.toString().padLeft(2, '0');
