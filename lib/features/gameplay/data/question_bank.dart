import '../domain/models/question.dart';
import 'questions/literature_language_questions.dart';
import 'questions/health_medicine_questions.dart';
import 'questions/food_crafts_questions.dart';
import 'questions/engineering_earth_questions.dart';
import 'questions/world_society_questions.dart';

// Aggregate all questions from all topic files.
final List<Question> allQuestions = [
  ...agathaChrisztieQuestions,
  ...lilyMayneQuestions,
  ...frenchLiteratureQuestions,
  ...linguisticsQuestions,
  ...dictionariesQuestions,
  ...theologyQuestions,
  ...puzzlesQuestions,
  ...tennisQuestions,
  ...medicineQuestions,
  ...anatomyQuestions,
  ...therapyQuestions,
  ...adhdQuestions,
  ...autismQuestions,
  ...pharmaceuticalDrugsQuestions,
  ...recreationalDrugsQuestions,
  ...coffeeQuestions,
  ...coffeeBrewingQuestions,
  ...candyQuestions,
  ...crocheteingQuestions,
  ...socksQuestions,
  ...footwearQuestions,
  ...perfumesQuestions,
  ...mechanicalEngineeringQuestions,
  ...chemicalEngineeringQuestions,
  ...bridgesQuestions,
  ...plasticsQuestions,
  ...handheldDevicesQuestions,
  ...rocksQuestions,
  ...physicalGeographyQuestions,
  ...waterBodiesQuestions,
  ...deepSeaQuestions,
  ...humanGeographyQuestions,
  ...countriesQuestions,
  ...westAfricanHistoryQuestions,
  ...medievalHistoryQuestions,
];

/// Select [count] random [QuizQuestion]s from topics in [topicIds].
/// Returns the shuffled list ready for a game session.
List<QuizQuestion> selectQuestions({
  required Set<String> topicIds,
  required int count,
}) {
  final pool = allQuestions
      .where((q) => topicIds.contains(q.topicId))
      .toList()
    ..shuffle();

  final selected = pool.take(count).toList();
  return selected.map((q) => q.toQuizQuestion()).toList();
}
