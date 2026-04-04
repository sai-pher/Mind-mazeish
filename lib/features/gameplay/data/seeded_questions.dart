import '../domain/models/question.dart';

/// One hand-crafted question per room, used when no Anthropic API key is
/// configured. All questions are grounded in real Wikipedia articles.
const Map<String, Question> seededQuestions = {
  'entrance': Question(
    question:
        'What was the primary defensive purpose of a castle\'s drawbridge?',
    options: [
      'To control entry by raising it against attackers',
      'To channel river water into the moat',
      'To provide a platform for archers',
      'To display the lord\'s coat of arms',
    ],
    correctIndex: 0,
    funFact:
        'The earliest drawbridges date to ancient Egypt — medieval European castles refined them into sophisticated counterweight systems.',
    articleTitle: 'Drawbridge',
    articleUrl: 'https://en.m.wikipedia.org/wiki/Drawbridge',
  ),

  'throne': Question(
    question:
        'In medieval Europe, which ceremony formally transferred royal power to a new monarch?',
    options: [
      'The coronation',
      'The investiture',
      'The enthronement',
      'The acclamation',
    ],
    correctIndex: 0,
    funFact:
        'The oldest surviving coronation ritual still in use is the British coronation ceremony, elements of which date to 973 AD.',
    articleTitle: 'Coronation',
    articleUrl: 'https://en.m.wikipedia.org/wiki/Coronation',
  ),

  'library': Question(
    question:
        'What revolutionary invention by Johannes Gutenberg around 1440 transformed the spread of books in Europe?',
    options: [
      'The movable-type printing press',
      'The mechanical quill',
      'The paper mill',
      'The illuminated manuscript machine',
    ],
    correctIndex: 0,
    funFact:
        'Gutenberg\'s press reduced the cost of books so dramatically that literacy rates across Europe roughly doubled within a century.',
    articleTitle: 'Printing press',
    articleUrl: 'https://en.m.wikipedia.org/wiki/Printing_press',
  ),

  'dungeon': Question(
    question:
        'In medieval castle design, what was the "oubliette" primarily used for?',
    options: [
      'A pit prison where prisoners were lowered and forgotten',
      'A torture chamber with iron maidens',
      'A food storage cellar below the great hall',
      'A secret escape tunnel for the lord',
    ],
    correctIndex: 0,
    funFact:
        'The word "oubliette" comes from the French "oublier" (to forget) — prisoners dropped in were quite literally forgotten.',
    articleTitle: 'Oubliette',
    articleUrl: 'https://en.m.wikipedia.org/wiki/Oubliette',
  ),

  'chapel': Question(
    question:
        'Which architectural feature, characteristic of Gothic cathedrals, allowed builders to construct taller, thinner walls with large windows?',
    options: [
      'The flying buttress',
      'The barrel vault',
      'The Roman arch',
      'The pendentive dome',
    ],
    correctIndex: 0,
    funFact:
        'Flying buttresses transfer the weight of the roof and walls to outer piers, allowing stained glass windows to fill entire walls — impossible in earlier Romanesque churches.',
    articleTitle: 'Flying buttress',
    articleUrl: 'https://en.m.wikipedia.org/wiki/Flying_buttress',
  ),

  'armory': Question(
    question:
        'What term describes the full suit of plate armour that a mounted knight wore into battle in the 14th–15th centuries?',
    options: [
      'Full plate armour',
      'Chain mail hauberk',
      'Brigandine',
      'Gambeson',
    ],
    correctIndex: 0,
    funFact:
        'A complete suit of Gothic plate armour weighed about 15–25 kg — less than a modern soldier\'s kit — and was carefully balanced so a fit knight could run, jump, and even mount a horse unaided.',
    articleTitle: 'Plate armour',
    articleUrl: 'https://en.m.wikipedia.org/wiki/Plate_armour',
  ),

  'kitchen': Question(
    question:
        'Which spice, more valuable than gold by weight in medieval Europe, was the primary driver of the Age of Exploration?',
    options: [
      'Black pepper',
      'Cinnamon',
      'Nutmeg',
      'Saffron',
    ],
    correctIndex: 0,
    funFact:
        'At the height of the medieval spice trade, a pound of black pepper could buy a sheep — its preservative and flavour properties made it the currency of European kitchens.',
    articleTitle: 'Spice trade',
    articleUrl: 'https://en.m.wikipedia.org/wiki/Spice_trade',
  ),

  'observatory': Question(
    question:
        'Which heliocentric model, published in 1543, proposed that the Earth orbits the Sun rather than the reverse?',
    options: [
      'Nicolaus Copernicus\'s De revolutionibus',
      'Galileo\'s Sidereus Nuncius',
      'Tycho Brahe\'s Tychonic system',
      'Johannes Kepler\'s Harmonices Mundi',
    ],
    correctIndex: 0,
    funFact:
        'Copernicus reportedly received the first printed copy of De revolutionibus on the day he died — May 24, 1543.',
    articleTitle: 'Nicolaus Copernicus',
    articleUrl: 'https://en.m.wikipedia.org/wiki/Nicolaus_Copernicus',
  ),

  'garden': Question(
    question:
        'Medieval alchemists famously sought two things: the Philosopher\'s Stone and which universal medicine said to cure all disease?',
    options: [
      'The Elixir of Life (Elixir vitae)',
      'The Holy Grail',
      'Aqua regia',
      'The Fifth Essence (Quintessence)',
    ],
    correctIndex: 0,
    funFact:
        'Though the Elixir was never found, alchemical experiments produced real discoveries — including early acids, distillation techniques, and the foundations of modern chemistry.',
    articleTitle: 'Alchemy',
    articleUrl: 'https://en.m.wikipedia.org/wiki/Alchemy',
  ),

  'tower': Question(
    question:
        'Which medieval siege weapon used a counterweight to hurl projectiles and could launch 90 kg stones over 300 metres?',
    options: [
      'The trebuchet',
      'The ballista',
      'The mangonel',
      'The onager',
    ],
    correctIndex: 0,
    funFact:
        'The trebuchet was so effective that some historians credit it with ending the era of castle warfare — no wall could withstand sustained bombardment.',
    articleTitle: 'Trebuchet',
    articleUrl: 'https://en.m.wikipedia.org/wiki/Trebuchet',
  ),
};
