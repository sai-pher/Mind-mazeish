import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A draft feedback session that has been saved locally but not yet submitted.
class FeedbackDraft {
  final String id;

  /// 'general' or 'content'
  final String type;

  /// Flat map of field name → value (varies by type; see field name constants).
  final Map<String, String> fields;

  final DateTime createdAt;
  final DateTime updatedAt;

  // Field name constants for each type.
  static const fieldTitle          = 'title';
  static const fieldBody           = 'body';
  static const fieldCategory       = 'category';        // general
  static const fieldRequestType    = 'requestType';     // content
  static const fieldTopicId        = 'topicId';         // content
  static const fieldGiven          = 'given';           // bug
  static const fieldWhen           = 'when';            // bug
  static const fieldThenExpected   = 'thenExpected';    // bug
  static const fieldButActually    = 'butActually';     // bug
  static const fieldSupportingDetails = 'supportingDetails'; // bug

  const FeedbackDraft({
    required this.id,
    required this.type,
    required this.fields,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeedbackDraft.fromJson(Map<String, dynamic> json) => FeedbackDraft(
        id: json['id'] as String,
        type: json['type'] as String,
        fields: Map<String, String>.from(json['fields'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'fields': fields,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  FeedbackDraft copyWithUpdated(Map<String, String> newFields) => FeedbackDraft(
        id: id,
        type: type,
        fields: newFields,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  String get displayTitle => fields[fieldTitle]?.isNotEmpty == true
      ? fields[fieldTitle]!
      : '(no title)';
}

class FeedbackDraftRepository {
  static const _key = 'feedback_drafts_v1';

  Future<List<FeedbackDraft>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) {
          try {
            return FeedbackDraft.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<FeedbackDraft>()
        .toList();
  }

  Future<void> save(FeedbackDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadAll();
    final updated = [
      draft,
      ...existing.where((d) => d.id != draft.id),
    ];
    await prefs.setStringList(
      _key,
      updated.map((d) => jsonEncode(d.toJson())).toList(),
    );
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadAll();
    await prefs.setStringList(
      _key,
      existing
          .where((d) => d.id != id)
          .map((d) => jsonEncode(d.toJson()))
          .toList(),
    );
  }
}
