import 'dart:ui';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homebase_mobile/main.dart';

void main() {
  setUp(() {
    // main() normally awaits dotenv.load() before runApp() — the job
    // registry reads a secret from it at construction time, so tests that
    // pump MyApp() directly need it initialised too.
    dotenv.testLoad(fileInput: 'X_INTERNAL_HEADER=test\nGAS_SECRET=test');
  });

  testWidgets('Home screen renders the job list', (WidgetTester tester) async {
    // Use a tall viewport so the whole (short) job list fits without
    // needing to scroll to find items below the fold.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // "Homebase" appears twice: the header title and the (off-screen) drawer title.
    expect(find.text('Homebase'), findsNWidgets(2));
    // "Interesting Fact" appears twice: the category filter chip and the job name.
    expect(find.text('Random Media'), findsOneWidget);
    expect(find.text('Interesting Fact'), findsAtLeastNWidgets(1));
    expect(find.text('Random Trunk'), findsOneWidget);
  });

  testWidgets('Tapping a job opens its detail screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Random Media'));
    await tester.pumpAndSettle();

    expect(find.text('Run'), findsOneWidget);
    expect(find.text('Method'), findsOneWidget);
  });
}
