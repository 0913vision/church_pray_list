import 'prayer_data.dart';

class EditablePrayerItem {
  final String id;
  String content;
  final bool isNew;

  EditablePrayerItem({
    required this.id,
    this.content = '',
    this.isNew = false,
  });
}

class EditablePrayerSubsection {
  final String id;
  String name;
  List<EditablePrayerItem> items;
  final bool isNew;

  EditablePrayerSubsection({
    required this.id,
    this.name = '',
    List<EditablePrayerItem>? items,
    this.isNew = false,
  }) : items = items ?? [];
}

class EditablePrayerSection {
  final String id;
  String name;
  List<EditablePrayerItem> items;
  List<EditablePrayerSubsection> subsections;
  final bool isNew;

  EditablePrayerSection({
    required this.id,
    this.name = '',
    List<EditablePrayerItem>? items,
    List<EditablePrayerSubsection>? subsections,
    this.isNew = false,
  })  : items = items ?? [],
        subsections = subsections ?? [];
}

class EditablePrayerData {
  String title;
  String date;
  List<EditablePrayerSection> sections;

  EditablePrayerData({
    this.title = '',
    required this.date,
    required this.sections,
  });

  /// Convert PrayerData (from server/cache) to EditablePrayerData
  factory EditablePrayerData.fromPrayerData(PrayerData data) {
    final baseTimestamp = DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return EditablePrayerData(
      title: data.title,
      date: dateStr,
      sections: data.sections.asMap().entries.map((entry) {
        final sectionIndex = entry.key;
        final section = entry.value;
        return EditablePrayerSection(
          id: 'section-$baseTimestamp-$sectionIndex',
          name: section.name,
          items: (section.items ?? []).asMap().entries.map((itemEntry) {
            return EditablePrayerItem(
              id: 'item-$baseTimestamp-$sectionIndex-${itemEntry.key}',
              content: itemEntry.value,
            );
          }).toList(),
          subsections:
              (section.subsections ?? []).asMap().entries.map((subEntry) {
            final subIndex = subEntry.key;
            final sub = subEntry.value;
            return EditablePrayerSubsection(
              id: 'subsection-$baseTimestamp-$sectionIndex-$subIndex',
              name: sub.name,
              items: sub.items.asMap().entries.map((itemEntry) {
                return EditablePrayerItem(
                  id: 'sub-item-$baseTimestamp-$sectionIndex-$subIndex-${itemEntry.key}',
                  content: itemEntry.value,
                );
              }).toList(),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  /// Convert back to PrayerData for upload
  PrayerData toPrayerData() {
    final dateParts = date.split('-');
    final year = dateParts[0];
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2]);
    final autoTitle = '$year\uB144 $month\uC6D4 $day\uC77C \uAE30\uB3C4\uC81C\uBAA9';

    return PrayerData(
      title: autoTitle,
      sections: sections.map((section) {
        final sectionItems = section.items
            .map((item) => item.content.trim())
            .where((content) => content.isNotEmpty)
            .toList();

        final subsectionPayload = section.subsections
            .map((sub) => PrayerSubsection(
                  name: sub.name,
                  items: sub.items
                      .map((item) => item.content.trim())
                      .where((content) => content.isNotEmpty)
                      .toList(),
                ))
            .where((sub) => sub.items.isNotEmpty && sub.name.trim().isNotEmpty)
            .toList();

        return PrayerSection(
          name: section.name,
          items: sectionItems.isNotEmpty ? sectionItems : null,
          subsections:
              subsectionPayload.isNotEmpty ? subsectionPayload : null,
        );
      }).toList(),
      verse: const PrayerVerse(text: '', reference: ''),
    );
  }
}
