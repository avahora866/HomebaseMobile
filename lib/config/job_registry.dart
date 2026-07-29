import '../models/job.dart';
import 'app_config.dart';

const List<String> _mediaTypes = [
  'novel',
  'comic',
  'manga',
  'podcast',
  'movie',
  'animatedMovie',
  'tvshow',
  'anime',
  'webnovel',
  'fanfiction',
];

final List<Job> jobRegistry = [
  // ------------------------------------------------------------------
  // /media/randomPicker
  // ------------------------------------------------------------------
  Job(
    id: 'random_media',
    name: 'Random Media',
    description: 'Get a random media recommendation. '
        'Choose a type and, for fanfiction, a fandom and/or publisher.',
    endpoint: '/media/randomPicker',
    method: 'GET',
    category: JobCategory.media,
    params: [
      JobParam(
        key: 'media',
        label: 'Type',
        inputType: ParamInputType.dropdown,
        required: true,
        options: _mediaTypes,
      ),
      JobParam(
        key: 'fandom',
        label: 'Fandom',
        inputType: ParamInputType.multiSelectDropdown,
        required: false,
        // Options start empty — populated by API call when fanfiction is chosen
        options: [],
        dependsOnKey: 'media',
        dependsOnValue: 'fanfiction',
      ),
      JobParam(
        key: 'publisher',
        label: 'Publisher',
        inputType: ParamInputType.dropdown,
        required: false,
        // Options start empty — populated by API call when fanfiction is chosen
        options: [],
        dependsOnKey: 'media',
        dependsOnValue: 'fanfiction',
      ),
    ],
  ),

  Job(
    id: 'interesting_fact',
    name: 'Interesting Fact',
    description:
        'Get an interesting fact from one of the various fields I am interested in.',
    endpoint: '/facts/interestingFact',
    method: 'GET',
    category: JobCategory.interestingFact,
  ),

  Job(
    id: 'reset_interesting_fact',
    name: 'Reset Interesting Fact',
    description: 'Clear the used-concepts table so previously used facts '
        "can be picked again — use this if you don't want duplicates piling up.",
    endpoint: '/facts/resetInterestingFact',
    method: 'DELETE',
    category: JobCategory.interestingFact,
  ),

  // ------------------------------------------------------------------
  // Zettelkasten random trunk
  // ------------------------------------------------------------------
  Job(
    id: 'random_trunk',
    name: 'Random Trunk',
    description: 'Fetch a random knowledge trunk note from your Zettelkasten. '
        'Optionally filter by category.',
    endpoint: AppConfig.gasUrl,
    method: 'GET',
    category: JobCategory.cs,
    staticParams: {
      'action': 'random',
      'secret': AppConfig.gasSecret,
    },
    params: [
      JobParam(
        key: 'category',
        label: 'Category',
        inputType: ParamInputType.dropdown,
        required: false,
        // Populated automatically when the job screen opens
        options: [],
      ),
    ],
  ),

  // ------------------------------------------------------------------
  // Template
  // ------------------------------------------------------------------
  // Job(
  //   id: 'job_unique_id',
  //   name: 'Human Readable Name',
  //   description: 'What this endpoint does.',
  //   endpoint: '/your-domain/your-endpoint',
  //   method: 'GET',
  //   category: JobCategory.cs,
  //   params: [
  //     JobParam(
  //       key: 'myParam',
  //       label: 'My Param',
  //       inputType: ParamInputType.dropdown,
  //       required: true,
  //       options: ['option1', 'option2'],
  //     ),
  //   ],
  // ),
];
