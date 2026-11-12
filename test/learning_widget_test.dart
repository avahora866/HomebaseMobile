import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:homebase_mobile/main.dart';
import 'package:homebase_mobile/models/learning.dart';
import 'package:homebase_mobile/providers/learning_provider.dart';
import 'package:homebase_mobile/screens/learning_path_screen.dart';
import 'package:homebase_mobile/screens/specialisation_screen.dart';
import 'package:homebase_mobile/screens/topic_detail_screen.dart';
import 'package:homebase_mobile/theme/app_theme.dart';

import 'learning_fixtures.dart';

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: 'X_INTERNAL_HEADER=test\nGAS_SECRET=test');
  });

  /// A phone-sized viewport, so any layout overflow fails the test.
  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpScreen(WidgetTester tester, LearningProvider provider, Widget screen) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<LearningProvider>.value(
        value: provider,
        child: MaterialApp(theme: AppTheme.theme, home: screen),
      ),
    );
    // Let the screen's own (network-less, failing) load settle before seeding.
    await tester.pumpAndSettle();
  }

  testWidgets('Drawer opens the Learning Path screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Learning Path'));
    await tester.pumpAndSettle();

    // No network here, so the screen settles into its error state.
    expect(find.text('Learning Path'), findsOneWidget);
  });

  testWidgets('Fields overview shows capabilities and each rollup with coverage', (WidgetTester tester) async {
    usePhone(tester);
    final provider = LearningProvider();
    await pumpScreen(tester, provider, const LearningPathScreen());
    provider.seedFieldsForTest([cooking, robotics]);
    await tester.pumpAndSettle();

    expect(find.text('Cooking'), findsOneWidget);
    expect(find.text('2 specialisations'), findsNWidgets(2));
    expect(find.text('suggested order'), findsOneWidget);
    expect(find.text('nesting: flat'), findsOneWidget);
    expect(find.text('3.3 avg · 3 of 3 rated'), findsOneWidget);
    expect(find.text('no topics yet'), findsOneWidget);
    expect(find.text('BASIC'), findsNWidgets(2));

    await tester.tap(find.text('+ Specialisation').first);
    await tester.pumpAndSettle();
    expect(find.text('New Specialisation'), findsOneWidget);
  });

  testWidgets('Specialisation tree starts collapsed and expands level by level', (WidgetTester tester) async {
    usePhone(tester);
    final provider = LearningProvider();
    await pumpScreen(tester, provider, const SpecialisationScreen(specialisationId: 3));
    provider.seedDetailForTest(SpecialisationDetail.fromJson(frenchJson()));
    await tester.pumpAndSettle();

    expect(find.text('LEARNING PATH — COOKING'), findsOneWidget);
    expect(find.text('2.5 avg · 2 of 2 rated'), findsOneWidget);
    expect(find.text('Mother Sauces'), findsOneWidget);
    expect(find.text('DERIVED'), findsOneWidget);
    expect(find.text('Béchamel'), findsNothing);

    await tester.tap(find.byKey(const Key('topic-caret-1')));
    await tester.pumpAndSettle();
    expect(find.text('Béchamel'), findsOneWidget);
    expect(find.text('Velouté'), findsOneWidget);
    expect(find.text('Mornay'), findsNothing);

    await tester.tap(find.byKey(const Key('topic-caret-2')));
    await tester.pumpAndSettle();
    expect(find.text('Mornay'), findsOneWidget);
    expect(find.text('1 prereq · 1 log'), findsOneWidget);
    expect(find.text('Dinner party'), findsOneWidget);
  });

  testWidgets('Topic detail: leaf is rateable, ancestors and subtopics navigate in place',
      (WidgetTester tester) async {
    usePhone(tester);
    final provider = LearningProvider()..seedDetailForTest(SpecialisationDetail.fromJson(frenchJson()));
    await pumpScreen(tester, provider, const TopicDetailScreen(specialisationId: 3, topicId: 3));

    // Mornay: a rated leaf in a field with logs and suggested order.
    expect(find.text('Mornay'), findsOneWidget);
    expect(find.text('Set by hand — this is a leaf topic. Tap the same dot again to clear it.'), findsOneWidget);
    expect(find.byKey(const Key('confidence-dot-1')), findsOneWidget);
    expect(find.text('Suggested order 10'), findsOneWidget);
    expect(find.text('Gruyère melts smoother than cheddar here.'), findsOneWidget);
    expect(find.text('23 Sep 2026'), findsOneWidget);
    expect(find.text('+ Add Subtopic'), findsOneWidget);

    // Jump two levels up via the breadcrumb.
    await tester.tap(find.text('MOTHER SAUCES'));
    await tester.pumpAndSettle();
    expect(find.text('DERIVED · READ-ONLY'), findsOneWidget);
    expect(find.text('Averaged from 2 subtopics. Unrated subtopics are excluded.'), findsOneWidget);
    expect(find.byKey(const Key('confidence-dot-1')), findsNothing);

    // And back down through the subtopic list.
    await tester.tap(find.text('Béchamel'));
    await tester.pumpAndSettle();
    expect(find.text('MOTHER SAUCES'), findsOneWidget);
    expect(find.text('Averaged from 1 subtopic. Unrated subtopics are excluded.'), findsOneWidget);
  });

  testWidgets('Adding a subtopic to a hand-rated leaf warns the rating will be discarded',
      (WidgetTester tester) async {
    usePhone(tester);
    final provider = LearningProvider()..seedDetailForTest(SpecialisationDetail.fromJson(frenchJson()));
    await pumpScreen(tester, provider, const TopicDetailScreen(specialisationId: 3, topicId: 3));

    await tester.scrollUntilVisible(find.text('+ Add Subtopic'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('+ Add Subtopic'));
    await tester.pumpAndSettle();

    expect(find.text('New Subtopic'), findsOneWidget);
    expect(find.text('Under Mother Sauces › Béchamel › Mornay.'), findsOneWidget);
    expect(find.textContaining('Adding a subtopic discards that rating'), findsOneWidget);
  });

  testWidgets('A flat field hides logs and blocks subtopics', (WidgetTester tester) async {
    usePhone(tester);
    final provider = LearningProvider()..seedDetailForTest(SpecialisationDetail.fromJson(dronesJson()));
    await pumpScreen(tester, provider, const TopicDetailScreen(specialisationId: 6, topicId: 11));

    expect(find.text('ESC & Motor Tuning'), findsOneWidget);
    expect(find.text('Flight Dynamics'), findsOneWidget); // prerequisite chip
    expect(find.text('FPV quad build'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('LOGS'), findsNothing);
    expect(find.textContaining('Suggested order'), findsNothing);
    expect(find.text('Subtopics not allowed (flat field)'), findsOneWidget);
  });
}
