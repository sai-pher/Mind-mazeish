import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/notebook_entry.dart';

class NotebookRepository {
  static const _key = 'notebook_entries_v2';

  Future<List<NotebookEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) {
          try {
            return NotebookEntry.fromJson(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<NotebookEntry>()
        .toList();
  }

  Future<void> save(NotebookEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadAll();
    // Deduplicate by URL
    final deduped = existing.where((e) => e.articleUrl != entry.articleUrl).toList();
    deduped.insert(0, entry);
    await prefs.setStringList(
      _key,
      deduped.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<bool> contains(String articleUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.any((s) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        return m['articleUrl'] == articleUrl;
      } catch (_) {
        return false;
      }
    });
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
