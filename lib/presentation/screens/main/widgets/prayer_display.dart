import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/prayer_data.dart';
import '../../../providers/font_size_provider.dart';

class PrayerDisplay extends ConsumerWidget {
  const PrayerDisplay({
    super.key,
    required this.title,
    required this.sections,
    this.verse,
  });

  final String title;
  final List<PrayerSection> sections;
  final PrayerVerse? verse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor =
        isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151);
    final headingColor = isDark ? Colors.white : const Color(0xFF111827);
    final sectionColor =
        isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937);

    double scaled(double base) => base * (fontSize / 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          title,
          style: TextStyle(
            fontSize: scaled(24),
            fontWeight: FontWeight.w600,
            color: headingColor,
          ),
        ),

        // Sections
        for (final section in sections) ...[
          const SizedBox(height: 24),
          // Section name
          Text(
            '<${section.name}>',
            style: TextStyle(
              fontSize: scaled(16),
              fontWeight: FontWeight.w600,
              color: sectionColor,
            ),
          ),
          const SizedBox(height: 12),

          // Items and subsections with indent
          if ((section.items != null && section.items!.isNotEmpty) ||
              (section.subsections != null &&
                  section.subsections!.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Numbered items
                  if (section.items != null)
                    for (int i = 0; i < section.items!.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${i + 1}. ',
                              style: TextStyle(
                                fontSize: scaled(16),
                                color: textColor,
                                height: 1.5,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                section.items![i],
                                style: TextStyle(
                                  fontSize: scaled(16),
                                  color: textColor,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                  // Subsections
                  if (section.subsections != null)
                    for (final subsection in section.subsections!) ...[
                      const SizedBox(height: 16),
                      // Subsection name with bullet
                      Text(
                        '\u2022 ${subsection.name}',
                        style: TextStyle(
                          fontSize: scaled(16),
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Subsection items (indented)
                      if (subsection.items.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0;
                                  i < subsection.items.length;
                                  i++)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${i + 1}. ',
                                        style: TextStyle(
                                          fontSize: scaled(16),
                                          color: textColor,
                                          height: 1.5,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          subsection.items[i],
                                          style: TextStyle(
                                            fontSize: scaled(16),
                                            color: textColor,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}
