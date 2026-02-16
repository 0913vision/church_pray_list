import 'package:flutter/foundation.dart';
import '../datasources/local/local_storage.dart';
import '../datasources/remote/supabase_datasource.dart';
import '../models/prayer_data.dart';

class PrayerRepository {
  PrayerRepository({
    SupabaseDatasource? remoteDatasource,
    LocalStorage? localStorage,
  })  : _remote = remoteDatasource ?? SupabaseDatasource(),
        _local = localStorage ?? LocalStorage();

  final SupabaseDatasource _remote;
  final LocalStorage _local;

  /// Load cached prayer data from local storage
  Future<PrayerData?> loadCachedData() async {
    return _local.loadCachedPrayer();
  }

  /// Fetch latest prayer from server, cache it, and return
  Future<PrayerData?> fetchLatestPrayer() async {
    try {
      final record = await _remote.fetchLatestPrayer();
      if (record == null) return null;

      final prayerData = record.toPrayerData();
      await _local.saveCachedPrayer(prayerData);
      return prayerData;
    } catch (e) {
      debugPrint('Error fetching prayer: $e');
      return null;
    }
  }

  /// Upload prayer data to server
  Future<bool> uploadPrayer(PrayerData data) async {
    try {
      await _remote.uploadPrayer(data);
      return true;
    } catch (e) {
      debugPrint('Error uploading prayer: $e');
      return false;
    }
  }
}
