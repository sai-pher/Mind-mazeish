import '../domain/models/topic.dart';

const List<SuperCategory> superCategories = [
  SuperCategory(
    id: 'literature_arts',
    name: 'Literature & Arts',
    emoji: '📚',
    categories: [
      TopicCategory(
        id: 'authors',
        name: 'Authors',
        superCategoryId: 'literature_arts',
        topics: [
          Topic(id: 'agatha_christie', name: 'Agatha Christie', categoryId: 'authors', emoji: '🔍'),
          Topic(id: 'lily_mayne', name: 'Lily Mayne', categoryId: 'authors', emoji: '📖'),
        ],
      ),
      TopicCategory(
        id: 'world_literature',
        name: 'World Literature',
        superCategoryId: 'literature_arts',
        topics: [
          Topic(id: 'french_literature', name: 'French Literature', categoryId: 'world_literature', emoji: '🗼'),
        ],
      ),
    ],
  ),

  SuperCategory(
    id: 'health_medicine',
    name: 'Health & Medicine',
    emoji: '🏥',
    categories: [
      TopicCategory(
        id: 'clinical',
        name: 'Clinical',
        superCategoryId: 'health_medicine',
        topics: [
          Topic(id: 'medicine', name: 'Medicine', categoryId: 'clinical', emoji: '⚕️'),
          Topic(id: 'anatomy', name: 'Anatomy', categoryId: 'clinical', emoji: '🫀'),
        ],
      ),
      TopicCategory(
        id: 'mental_health',
        name: 'Mental Health',
        superCategoryId: 'health_medicine',
        topics: [
          Topic(id: 'therapy', name: 'Therapy', categoryId: 'mental_health', emoji: '🧠'),
          Topic(id: 'adhd', name: 'ADHD', categoryId: 'mental_health', emoji: '⚡'),
          Topic(id: 'autism', name: 'Autism', categoryId: 'mental_health', emoji: '🌈'),
        ],
      ),
      TopicCategory(
        id: 'pharmacology',
        name: 'Pharmacology',
        superCategoryId: 'health_medicine',
        topics: [
          Topic(id: 'pharmaceutical_drugs', name: 'Pharmaceutical Drugs', categoryId: 'pharmacology', emoji: '💊'),
          Topic(id: 'recreational_drugs', name: 'Recreational Drugs', categoryId: 'pharmacology', emoji: '🌿'),
        ],
      ),
    ],
  ),

  SuperCategory(
    id: 'food_drink',
    name: 'Food & Drink',
    emoji: '☕',
    categories: [
      TopicCategory(
        id: 'beverages',
        name: 'Beverages',
        superCategoryId: 'food_drink',
        topics: [
          Topic(id: 'coffee', name: 'Coffee', categoryId: 'beverages', emoji: '☕'),
          Topic(id: 'coffee_brewing', name: 'Coffee Brewing', categoryId: 'beverages', emoji: '🫖'),
        ],
      ),
      TopicCategory(
        id: 'confectionery',
        name: 'Confectionery',
        superCategoryId: 'food_drink',
        topics: [
          Topic(id: 'candy', name: 'Candy', categoryId: 'confectionery', emoji: '🍬'),
        ],
      ),
    ],
  ),

  SuperCategory(
    id: 'engineering_tech',
    name: 'Engineering & Technology',
    emoji: '⚙️',
    categories: [
      TopicCategory(
        id: 'engineering',
        name: 'Engineering',
        superCategoryId: 'engineering_tech',
        topics: [
          Topic(id: 'mechanical_engineering', name: 'Mechanical Engineering', categoryId: 'engineering', emoji: '⚙️'),
          Topic(id: 'chemical_engineering', name: 'Chemical Engineering', categoryId: 'engineering', emoji: '⚗️'),
          Topic(id: 'bridges', name: 'Bridges', categoryId: 'engineering', emoji: '🌉'),
        ],
      ),
      TopicCategory(
        id: 'materials',
        name: 'Materials',
        superCategoryId: 'engineering_tech',
        topics: [
          Topic(id: 'plastics', name: 'Plastics', categoryId: 'materials', emoji: '♻️'),
        ],
      ),
      TopicCategory(
        id: 'devices',
        name: 'Devices',
        superCategoryId: 'engineering_tech',
        topics: [
          Topic(id: 'handheld_devices', name: 'Handheld Devices', categoryId: 'devices', emoji: '📱'),
        ],
      ),
    ],
  ),

  SuperCategory(
    id: 'earth_environment',
    name: 'Earth & Environment',
    emoji: '🌍',
    categories: [
      TopicCategory(
        id: 'geology',
        name: 'Geology',
        superCategoryId: 'earth_environment',
        topics: [
          Topic(id: 'rocks', name: 'Rocks & Geology', categoryId: 'geology', emoji: '🪨'),
        ],
      ),
      TopicCategory(
        id: 'physical_world',
        name: 'Physical World',
        superCategoryId: 'earth_environment',
        topics: [
          Topic(id: 'physical_geography', name: 'Physical Geography', categoryId: 'physical_world', emoji: '🗺️'),
          Topic(id: 'water_bodies', name: 'Water Bodies', categoryId: 'physical_world', emoji: '🌊'),
          Topic(id: 'deep_sea', name: 'Deep Sea', categoryId: 'physical_world', emoji: '🦑'),
        ],
      ),
    ],
  ),

  SuperCategory(
    id: 'world_society',
    name: 'World & Society',
    emoji: '🌐',
    categories: [
      TopicCategory(
        id: 'geography_society',
        name: 'Geography',
        superCategoryId: 'world_society',
        topics: [
          Topic(id: 'human_geography', name: 'Human Geography', categoryId: 'geography_society', emoji: '🏙️'),
          Topic(id: 'countries', name: 'Countries', categoryId: 'geography_society', emoji: '🗾'),
        ],
      ),
      TopicCategory(
        id: 'history',
        name: 'History',
        superCategoryId: 'world_society',
        topics: [
          Topic(id: 'west_african_history', name: 'West African History', categoryId: 'history', emoji: '🌍'),
          Topic(id: 'medieval_history', name: 'Medieval History', categoryId: 'history', emoji: '🏰'),
        ],
      ),
    ],
  ),

  SuperCategory(
    id: 'language_culture',
    name: 'Language & Culture',
    emoji: '💬',
    categories: [
      TopicCategory(
        id: 'language',
        name: 'Language',
        superCategoryId: 'language_culture',
        topics: [
          Topic(id: 'linguistics', name: 'Linguistics', categoryId: 'language', emoji: '🗣️'),
          Topic(id: 'dictionaries', name: 'Dictionaries', categoryId: 'language', emoji: '📕'),
        ],
      ),
      TopicCategory(
        id: 'belief',
        name: 'Theology & Belief',
        superCategoryId: 'language_culture',
        topics: [
          Topic(id: 'theology', name: 'Theology', categoryId: 'belief', emoji: '✨'),
        ],
      ),
    ],
  ),

  SuperCategory(
    id: 'fashion_crafts',
    name: 'Fashion & Crafts',
    emoji: '🧶',
    categories: [
      TopicCategory(
        id: 'textiles',
        name: 'Textiles',
        superCategoryId: 'fashion_crafts',
        topics: [
          Topic(id: 'crocheting', name: 'Crocheting', categoryId: 'textiles', emoji: '🧶'),
          Topic(id: 'socks', name: 'Socks', categoryId: 'textiles', emoji: '🧦'),
        ],
      ),
      TopicCategory(
        id: 'style',
        name: 'Style & Beauty',
        superCategoryId: 'fashion_crafts',
        topics: [
          Topic(id: 'footwear', name: 'Footwear', categoryId: 'style', emoji: '👟'),
          Topic(id: 'perfumes', name: 'Perfumes', categoryId: 'style', emoji: '🌸'),
        ],
      ),
    ],
  ),

  SuperCategory(
    id: 'sports_recreation',
    name: 'Sports & Recreation',
    emoji: '🎾',
    categories: [
      TopicCategory(
        id: 'sport',
        name: 'Sport',
        superCategoryId: 'sports_recreation',
        topics: [
          Topic(id: 'tennis', name: 'Tennis', categoryId: 'sport', emoji: '🎾'),
        ],
      ),
      TopicCategory(
        id: 'games_puzzles',
        name: 'Games & Puzzles',
        superCategoryId: 'sports_recreation',
        topics: [
          Topic(id: 'puzzles', name: 'Puzzles', categoryId: 'games_puzzles', emoji: '🧩'),
        ],
      ),
    ],
  ),
];

/// Flat map of topicId → Topic for quick lookup.
final Map<String, Topic> topicById = {
  for (final sc in superCategories)
    for (final cat in sc.categories)
      for (final topic in cat.topics) topic.id: topic,
};

/// All topic IDs.
final List<String> allTopicIds = topicById.keys.toList();

/// Get the emoji for a topic ID, falling back to a castle.
String topicEmoji(String topicId) =>
    topicById[topicId]?.emoji ?? '🏰';

/// Get the display name for a topic ID.
String topicName(String topicId) =>
    topicById[topicId]?.name ?? topicId;
