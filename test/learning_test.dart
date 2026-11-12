import 'package:flutter_test/flutter_test.dart';

import 'package:homebase_mobile/models/learning.dart';
import 'package:homebase_mobile/models/project.dart';
import 'package:homebase_mobile/providers/learning_provider.dart';

import 'learning_fixtures.dart';

void main() {
  group('rating formatting', () {
    test('formatRating shows one decimal only when needed, and a dash for unrated', () {
      expect(formatRating(null), '—');
      expect(formatRating(3), '3');
      expect(formatRating(3.25), '3.3');
      expect(formatRating(4.04), '4');
    });

    test('dotFills fills whole steps, marks a part step, and leaves unrated empty', () {
      expect(dotFills(null), List.filled(5, DotFill.empty));
      expect(dotFills(3), [DotFill.full, DotFill.full, DotFill.full, DotFill.empty, DotFill.empty]);
      expect(dotFills(3.5), [DotFill.full, DotFill.full, DotFill.full, DotFill.partial, DotFill.empty]);
      // Within a quarter of the next step counts as full.
      expect(dotFills(3.8)[3], DotFill.full);
    });

    test('rollupLabel pairs the average with leaf coverage', () {
      expect(rollupLabel(3.75, 4, 5), '3.8 avg · 4 of 5 rated');
      expect(rollupLabel(null, 0, 0), 'no topics yet');
      expect(rollupLabel(null, 0, 0, empty: 'No topics yet'), 'No topics yet');
    });

    test('formatLogDate', () {
      expect(formatLogDate(DateTime(2026, 9, 12, 14, 3)), '12 Sep 2026');
    });
  });

  group('SpecialisationDetail', () {
    final detail = SpecialisationDetail.fromJson(frenchJson());

    test('parses the server payload, including decimal ratings and project links', () {
      expect(detail.fieldName, 'Cooking');
      expect(detail.rollupRating, 2.5);
      expect(detail.topics.map((t) => t.name), ['Mother Sauces', 'Béchamel', 'Mornay', 'Velouté']);
      final mornay = detail.topic(3)!;
      expect(mornay.prerequisiteIds, [2]);
      expect(mornay.logs.single.note, 'Gruyère melts smoother than cheddar here.');
      expect(detail.projectLinks.single.projectStatus, ProjectStatus.inProgress);
    });

    test('walks the tree', () {
      final mornay = detail.topic(3)!;
      expect(detail.ancestorsOf(mornay).map((t) => t.name), ['Mother Sauces', 'Béchamel']);
      expect(detail.childrenOf(1).map((t) => t.name), ['Béchamel', 'Velouté']);
      expect(detail.descendantCount(1), 3);
      expect(detail.canNestUnder(mornay), isTrue);
    });

    test('respects the nesting limit', () {
      final flat = SpecialisationDetail.fromJson(dronesJson());
      expect(flat.canNestUnder(flat.topics.first), isFalse);
    });
  });

  test('capability labels match the field card tags', () {
    expect(robotics.capabilities.labels, ['prerequisites', 'project links', 'nesting: flat']);
    expect(cooking.capabilities.labels, ['prerequisites', 'suggested order', 'logs', 'project links', 'nesting: unlimited']);
  });

  test('a refreshed specialisation patches its summary on the field card', () {
    final provider = LearningProvider()..seedFieldsForTest([cooking]);
    final refreshed = frenchJson()
      ..['rollupRating'] = 4.0
      ..['ratedLeafCount'] = 3;

    provider.seedDetailForTest(SpecialisationDetail.fromJson(refreshed));

    final french = provider.fields.single.specialisations.firstWhere((s) => s.name == 'French');
    expect(french.rollupRating, 4.0);
    expect(french.ratedLeafCount, 3);
    expect(provider.detail(3)!.rollupRating, 4.0);
  });
}
