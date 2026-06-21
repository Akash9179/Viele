import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Account-level privacy actions backed by Supabase Edge Functions:
/// real data export and real cascading account deletion. Both require a valid
/// session (the functions are `verify_jwt = true`); supabase_flutter attaches
/// the caller's JWT to `functions.invoke` automatically.
class AccountRepository {
  SupabaseClient get _c => Supabase.instance.client;

  /// Fetches the full data export and returns it as pretty-printed JSON.
  Future<String> exportData() async {
    final res = await _c.functions.invoke('export-data');
    if (res.status != 200) {
      throw Exception('Export failed (${res.status})');
    }
    // Edge function returns JSON; supabase_flutter decodes it into `data`.
    return const JsonEncoder.withIndent('  ').convert(res.data);
  }

  /// Permanently deletes the signed-in account (cascades DB + storage).
  Future<void> deleteAccount() async {
    final res = await _c.functions.invoke('delete-account');
    if (res.status != 200) {
      final msg = res.data is Map ? res.data['error'] : null;
      throw Exception(msg ?? 'Deletion failed (${res.status})');
    }
  }
}

final accountRepositoryProvider =
    Provider<AccountRepository>((_) => AccountRepository());
