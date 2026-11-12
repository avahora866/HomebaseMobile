import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:homebase_mobile/providers/job_provider.dart';
import 'package:homebase_mobile/screens/job_detail_screen.dart';
import 'package:homebase_mobile/widgets/media_search_results.dart';

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: 'X_INTERNAL_HEADER=test\nGAS_SECRET=test');
  });

  Widget detailScreen(JobProvider provider) => ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: JobDetailScreen(jobId: 'media_search')),
      );

  testWidgets('Media Search shows a type dropdown and a title text box', (tester) async {
    final provider = JobProvider();
    await tester.pumpWidget(detailScreen(provider));
    await tester.pumpAndSettle();

    expect(find.text('Select Type'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'dune');
    provider.setParamValue('media_search', 'media', 'novel');
    await tester.pumpAndSettle();

    final job = provider.jobs.firstWhere((j) => j.id == 'media_search');
    expect(job.resolvedEndpoint, '/media/search?media=novel&title=dune');
  });

  testWidgets('Reset clears the title text box', (tester) async {
    final provider = JobProvider();
    await tester.pumpWidget(detailScreen(provider));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'dune');
    await tester.pump();
    provider.resetJob('media_search');
    await tester.pumpAndSettle();

    expect(find.text('dune'), findsNothing);
  });

  testWidgets('Search results render each match with its status', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: MediaSearchResults(mediaType: 'movie', results: [
            {'name': 'Dune', 'status': 'Finished', 'notionUrl': 'https://notion.so/a'},
            {'name': 'Dune: Part Two', 'summary': 'Paul unites with the Fremen.', 'notionUrl': 'https://notion.so/b'},
          ]),
        ),
      ),
    ));

    expect(find.text('2 matches'), findsOneWidget);
    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('FINISHED'), findsOneWidget);
    expect(find.text('Paul unites with the Fremen.'), findsOneWidget);
    expect(find.text('TMDB'), findsNWidgets(2));
  });
}
