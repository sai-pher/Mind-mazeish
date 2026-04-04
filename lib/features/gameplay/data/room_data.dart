import '../domain/models/room.dart';
import '../domain/models/game_state.dart';

const List<RoomTheme> roomThemes = [
  RoomTheme(
    id: 'entrance',
    name: 'Castle Entrance',
    wikiTopics: ['castle', 'medieval architecture', 'drawbridge'],
  ),
  RoomTheme(
    id: 'throne',
    name: 'Throne Room',
    wikiTopics: ['monarchy', 'crown', 'king'],
  ),
  RoomTheme(
    id: 'library',
    name: 'Great Library',
    wikiTopics: ['ancient library', 'manuscript', 'printing press'],
  ),
  RoomTheme(
    id: 'dungeon',
    name: 'The Dungeon',
    wikiTopics: ['dungeon', 'torture', 'medieval punishment'],
  ),
  RoomTheme(
    id: 'chapel',
    name: 'Chapel',
    wikiTopics: ['cathedral', 'Christianity', 'gothic architecture'],
  ),
  RoomTheme(
    id: 'armory',
    name: 'The Armory',
    wikiTopics: ['sword', 'knight', 'medieval warfare'],
  ),
  RoomTheme(
    id: 'kitchen',
    name: 'Royal Kitchen',
    wikiTopics: ['medieval cuisine', 'feast', 'spice trade'],
  ),
  RoomTheme(
    id: 'observatory',
    name: 'Observatory',
    wikiTopics: ['astronomy', 'astrolabe', 'Copernicus'],
  ),
  RoomTheme(
    id: 'garden',
    name: 'Castle Garden',
    wikiTopics: ['herbalism', 'medieval garden', 'alchemy'],
  ),
  RoomTheme(
    id: 'tower',
    name: 'The Tower',
    wikiTopics: ['siege warfare', 'trebuchet', 'crusades'],
  ),
];

GameState buildInitialGameState() {
  final rooms = roomThemes
      .asMap()
      .entries
      .map((e) => Room(index: e.key, theme: e.value))
      .toList();

  return GameState(
    rooms: rooms,
    currentRoomIndex: 0,
    score: 0,
    lives: 3,
    status: GameStatus.loading,
    usedArticleTitles: {},
  );
}
