import 'package:supabase_flutter/supabase_flutter.dart';

/// Non-destructive cloud backup for the existing local-first Farmer Calendar.
class HpjReminderRepository {
  static SupabaseClient get _db => Supabase.instance.client;

  static Future<void> backup(String farmerId, List<Map<String, dynamic>> reminders) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null || farmerId.isEmpty || reminders.isEmpty) return;
    await _db.from('hpj_farmer_reminders').upsert(
      reminders.map((r) => <String, dynamic>{
        'user_id': userId,
        'farmer_id': farmerId,
        'notification_id': r['notification_id'],
        'title': r['title'],
        'event_at': r['event_at'],
        'notify_at': r['notify_at'],
        'remind_before_minutes': r['remind_before_minutes'],
        'crop_name': r['crop_name'],
      }).toList(),
      onConflict: 'user_id,farmer_id,notification_id',
    );
  }

  static Future<List<Map<String, dynamic>>> load(String farmerId) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null || farmerId.isEmpty) return [];
    final rows = await _db.from('hpj_farmer_reminders')
      .select('notification_id,title,event_at,notify_at,remind_before_minutes,crop_name')
      .eq('user_id', userId).eq('farmer_id', farmerId)
      .order('event_at');
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  static Future<void> delete(String farmerId, int notificationId) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null || farmerId.isEmpty) return;
    await _db.from('hpj_farmer_reminders').delete()
      .eq('user_id', userId).eq('farmer_id', farmerId)
      .eq('notification_id', notificationId);
  }
}
