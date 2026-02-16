import 'dart:convert';

class PrayerVerse {
  final String text;
  final String reference;

  const PrayerVerse({required this.text, required this.reference});

  factory PrayerVerse.fromJson(Map<String, dynamic> json) {
    return PrayerVerse(
      text: json['text'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'text': text, 'reference': reference};
}

class PrayerSubsection {
  final String name;
  final List<String> items;

  const PrayerSubsection({required this.name, required this.items});

  factory PrayerSubsection.fromJson(Map<String, dynamic> json) {
    return PrayerSubsection(
      name: json['name'] as String? ?? '',
      items: _normalizeItems(json['items']),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'items': items};
}

class PrayerSection {
  final String name;
  final List<String>? items;
  final List<PrayerSubsection>? subsections;

  const PrayerSection({required this.name, this.items, this.subsections});

  factory PrayerSection.fromJson(Map<String, dynamic> json) {
    final normalizedItems = _normalizeItems(json['items']);
    final normalizedSubsections = _normalizeSubsections(json['subsections']);

    return PrayerSection(
      name: json['name'] as String? ?? '',
      items: normalizedItems.isNotEmpty ? normalizedItems : null,
      subsections:
          normalizedSubsections.isNotEmpty ? normalizedSubsections : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'name': name};
    if (items != null && items!.isNotEmpty) map['items'] = items;
    if (subsections != null && subsections!.isNotEmpty) {
      map['subsections'] = subsections!.map((s) => s.toJson()).toList();
    }
    return map;
  }
}

class PrayerData {
  final String title;
  final List<PrayerSection> sections;
  final PrayerVerse? verse;

  const PrayerData({
    required this.title,
    required this.sections,
    this.verse,
  });

  factory PrayerData.fromJson(Map<String, dynamic> json) {
    return PrayerData(
      title: json['title'] as String? ?? '',
      sections: _normalizeSections(json['sections']),
      verse: json['verse'] != null
          ? PrayerVerse.fromJson(json['verse'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'sections': sections.map((s) => s.toJson()).toList(),
        if (verse != null) 'verse': verse!.toJson(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory PrayerData.fromJsonString(String jsonString) {
    return PrayerData.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}

class PrayerRecord {
  final String id;
  final String title;
  final Map<String, dynamic> content;
  final String createdAt;

  const PrayerRecord({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory PrayerRecord.fromJson(Map<String, dynamic> json) {
    return PrayerRecord(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      content: json['content'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  PrayerData toPrayerData() {
    return PrayerData(
      title: title,
      sections: _normalizeSections(content['sections']),
      verse: content['verse'] != null
          ? PrayerVerse.fromJson(content['verse'] as Map<String, dynamic>)
          : null,
    );
  }
}

// Normalization helpers (matching RN's normalizeItems, normalizeSections etc.)
List<String> _normalizeItems(dynamic items) {
  if (items is! List) return [];
  return items
      .map((item) => item is String ? item : '')
      .where((item) => item.trim().isNotEmpty)
      .cast<String>()
      .toList();
}

List<PrayerSubsection> _normalizeSubsections(dynamic subsections) {
  if (subsections is! List) return [];
  return subsections
      .map((sub) {
        if (sub is! Map<String, dynamic>) {
          return const PrayerSubsection(name: '', items: []);
        }
        return PrayerSubsection.fromJson(sub);
      })
      .where((sub) => sub.items.isNotEmpty)
      .toList();
}

List<PrayerSection> _normalizeSections(dynamic sections) {
  if (sections is! List) return [];
  return sections.map((section) {
    if (section is! Map<String, dynamic>) {
      return const PrayerSection(name: '');
    }
    return PrayerSection.fromJson(section);
  }).toList();
}
