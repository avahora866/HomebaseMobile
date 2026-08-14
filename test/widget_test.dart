import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:homebase_mobile/main.dart';
import 'package:homebase_mobile/models/project.dart' as pm;
import 'package:homebase_mobile/models/task.dart' as tm;
import 'package:homebase_mobile/providers/project_provider.dart';
import 'package:homebase_mobile/screens/project_detail_screen.dart';
import 'package:homebase_mobile/screens/project_tracker_screen.dart';
import 'package:homebase_mobile/theme/app_theme.dart';

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

  testWidgets('Drawer opens the Project Tracker screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Project Tracker'));
    await tester.pumpAndSettle();

    // Network is unavailable in the test environment, so the screen settles
    // into its error state — just confirm the screen itself opened cleanly.
    expect(find.text('Project Tracker'), findsOneWidget);
  });

  testWidgets('Project detail renders tasks and opens the edit sheets', (WidgetTester tester) async {
    final category = pm.ProjectCategory(id: 1, name: 'Work');
    final now = DateTime(2026, 1, 1);
    final project = pm.Project(
      id: 1,
      name: 'Homebase Mobile',
      description: 'Flutter client for the job runner & budget tools.',
      status: pm.ProjectStatus.development,
      categoryId: category.id,
      categoryName: category.name,
      taskCount: 1,
      createdAt: now,
      updatedAt: now,
    );
    final task = tm.Task(
      id: 1,
      projectId: 1,
      title: 'Design tracker tab',
      description: 'Flow diagram, task list layout.',
      status: tm.TaskStatus.todo,
      priority: tm.TaskPriority.high,
      subtasks: [tm.Subtask(id: 1, title: 'Sketch flow map', done: true)],
      createdAt: now,
      updatedAt: now,
    );

    final provider = ProjectProvider()
      ..status = ProjectTrackerStatus.success
      ..categories = [category]
      ..projects = [project];

    await tester.pumpWidget(
      ChangeNotifierProvider<ProjectProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.theme,
          home: ProjectDetailScreen(projectId: project.id),
        ),
      ),
    );
    // Let the initState post-frame task-loading callback settle before
    // manually seeding the task cache (avoids a real network round trip).
    await tester.pump();
    provider.seedTasksForTest(project.id, [task]);
    await tester.pumpAndSettle();

    expect(find.text('Homebase Mobile'), findsOneWidget);
    expect(find.text('Design tracker tab'), findsOneWidget);
    expect(find.text('+ Add Task'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Edit Project'), findsOneWidget);
    // Dismiss the sheet by tapping the scrim well above its content.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Design tracker tab'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Task'), findsOneWidget);
  });

  testWidgets('Tracker home renders project cards grouped by status and opens New Project',
      (WidgetTester tester) async {
    final personal = pm.ProjectCategory(id: 1, name: 'Personal');
    final now = DateTime(2026, 1, 1);
    final idea = pm.Project(
      id: 1,
      name: 'Recipe box app',
      status: pm.ProjectStatus.idea,
      categoryId: personal.id,
      categoryName: personal.name,
      taskCount: 0,
      createdAt: now,
      updatedAt: now,
    );
    final inDev = pm.Project(
      id: 2,
      name: 'Homebase Mobile',
      status: pm.ProjectStatus.development,
      categoryId: personal.id,
      categoryName: personal.name,
      taskCount: 6,
      createdAt: now,
      updatedAt: now,
    );

    final provider = ProjectProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<ProjectProvider>.value(
        value: provider,
        child: MaterialApp(theme: AppTheme.theme, home: const ProjectTrackerScreen()),
      ),
    );
    // The screen's own initState kicks off a real (network-less, failing)
    // load() — let that settle, then seed data directly as if it succeeded.
    await tester.pumpAndSettle();
    provider.seedProjectsForTest(categories: [personal], projects: [idea, inDev]);
    await tester.pumpAndSettle();

    expect(find.text('Recipe box app'), findsOneWidget);
    expect(find.text('Personal · no tasks'), findsOneWidget);
    expect(find.text('Homebase Mobile'), findsOneWidget);
    expect(find.text('Personal · 6 tasks'), findsOneWidget);

    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();

    expect(find.text('New Project'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Project name'), 'New idea');
    await tester.tap(find.text('+ Add'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Category name'), findsOneWidget);
    // No live network in this test environment — submitting the inline add
    // just needs to fail gracefully rather than crash the sheet.
    await tester.enterText(find.widgetWithText(TextField, 'Category name'), 'Side projects');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('New Project'), findsOneWidget);
  });
}
