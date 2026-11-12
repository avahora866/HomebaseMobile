import 'package:homebase_mobile/models/learning.dart';

/// Shapes copied from the server's `/learning/**` responses.

Map<String, dynamic> _caps({bool order = false, bool logs = false, int? depth}) => {
      'allowsPrerequisites': true,
      'allowsSuggestedOrder': order,
      'allowsLogs': logs,
      'allowsProjectLinks': true,
      'maxNestingDepth': depth,
    };

Map<String, dynamic> _topic(
  int id,
  String name, {
  int? parent,
  int depth = 0,
  int? rating,
  double? effective,
  bool derived = false,
  int? order,
  List<int> prereqs = const [],
  List<Map<String, dynamic>> logs = const [],
  List<Map<String, dynamic>> links = const [],
}) =>
    {
      'id': id,
      'parentTopicId': parent,
      'name': name,
      'suggestedOrder': order,
      'confidenceRating': rating,
      'effectiveRating': effective ?? rating?.toDouble(),
      'derived': derived,
      'depth': depth,
      'prerequisiteIds': prereqs,
      'logs': logs,
      'projectLinks': links,
      'createdAt': '2026-09-23T09:30:00.123456',
    };

Map<String, dynamic> _link(int id, String name) =>
    {'id': id, 'projectId': id, 'projectName': name, 'projectStatus': 'IN_PROGRESS'};

/// Cooking › French: Mother Sauces › (Béchamel › Mornay 3, Velouté 2).
Map<String, dynamic> frenchJson() => {
      'id': 3,
      'fieldId': 2,
      'fieldName': 'Cooking',
      'name': 'French',
      'basic': false,
      'capabilities': _caps(order: true, logs: true),
      'rollupRating': 2.5,
      'ratedLeafCount': 2,
      'leafCount': 2,
      'topics': [
        _topic(1, 'Mother Sauces', effective: 2.5, derived: true, order: 10),
        _topic(2, 'Béchamel', parent: 1, depth: 1, effective: 3, derived: true, order: 10),
        _topic(3, 'Mornay', parent: 2, depth: 2, rating: 3, order: 10, prereqs: [
          2
        ], logs: [
          {'id': 1, 'createdAt': '2026-09-23T09:31:00', 'note': 'Gruyère melts smoother than cheddar here.'},
        ]),
        _topic(4, 'Velouté', parent: 1, depth: 1, rating: 2, order: 20),
      ],
      'projectLinks': [_link(7, 'Dinner party')],
    };

/// Robotics › Drones: flat, no logs.
Map<String, dynamic> dronesJson() => {
      'id': 6,
      'fieldId': 3,
      'fieldName': 'Robotics',
      'name': 'Drones',
      'basic': false,
      'capabilities': _caps(depth: 0),
      'rollupRating': 3.5,
      'ratedLeafCount': 2,
      'leafCount': 2,
      'topics': [
        _topic(10, 'Flight Dynamics', rating: 3),
        _topic(11, 'ESC & Motor Tuning', rating: 4, prereqs: [10], links: [_link(8, 'FPV quad build')]),
      ],
      'projectLinks': <Map<String, dynamic>>[],
    };

final cooking = LearningField.fromJson({
  'id': 2,
  'name': 'Cooking',
  'capabilities': _caps(order: true, logs: true),
  'specialisations': [
    {'id': 2, 'name': 'Basic', 'basic': true, 'rollupRating': 3.25, 'ratedLeafCount': 3, 'leafCount': 3},
    {'id': 3, 'name': 'French', 'basic': false, 'rollupRating': 2.5, 'ratedLeafCount': 2, 'leafCount': 2},
  ],
});

final robotics = LearningField.fromJson({
  'id': 3,
  'name': 'Robotics',
  'capabilities': _caps(depth: 0),
  'specialisations': [
    {'id': 5, 'name': 'Basic', 'basic': true, 'rollupRating': null, 'ratedLeafCount': 0, 'leafCount': 0},
    {'id': 6, 'name': 'Drones', 'basic': false, 'rollupRating': 3.5, 'ratedLeafCount': 2, 'leafCount': 2},
  ],
});
