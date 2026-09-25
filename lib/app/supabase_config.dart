/// Supabase connection. The publishable key is meant to ship in the app —
/// data is protected by Row Level Security (see supabase/schema.sql).
///
/// Leave [supabaseUrl] empty to run fully offline with on-device storage.
/// Both values can also be overridden at build time:
///   flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://vnmjtuzsknrvzkbenara.supabase.co',
);

const supabaseKey = String.fromEnvironment(
  'SUPABASE_KEY',
  defaultValue: 'sb_publishable_s72bIJp5BXZO-QTW9hSZ0A_iTCemtPe',
);

bool get useSupabase => supabaseUrl.isNotEmpty;
