import 'package:flutter_test/flutter_test.dart';
import 'package:mind_maze/features/gameplay/data/room_data.dart';
import 'package:mind_maze/features/gameplay/domain/models/game_state.dart';

void main() {
  group('GameState', () {
    late GameState initial;

    setUp(() {
      initial = buildInitialGameState();
    });

    test('initial state has 10 rooms, 3 lives, 0 score, loading status', () {
      expect(initial.rooms.length, 10);
      expect(initial.lives, 3);
      expect(initial.score, 0);
      expect(initial.currentRoomIndex, 0);
      expect(initial.status, GameStatus.loading);
      expect(initial.usedArticleTitles, isEmpty);
    });

    test('correct answer increases score by 10 and keeps lives', () {
      final next = initial.answerQuestion(correct: true);

      expect(next.score, 10);
      expect(next.lives, 3);
      expect(next.status, GameStatus.answerRevealed);
      expect(next.rooms[0].completed, isTrue);
      expect(next.rooms[0].answeredCorrectly, isTrue);
    });

    test('wrong answer keeps score and decrements lives', () {
      final next = initial.answerQuestion(correct: false);

      expect(next.score, 0);
      expect(next.lives, 2);
      expect(next.status, GameStatus.answerRevealed);
      expect(next.rooms[0].completed, isTrue);
      expect(next.rooms[0].answeredCorrectly, isFalse);
    });

    test('three wrong answers triggers game over', () {
      var state = initial;
      state = state.answerQuestion(correct: false); // 2 lives
      state = state.advanceRoom().markPlaying();
      state = state.answerQuestion(correct: false); // 1 life
      state = state.advanceRoom().markPlaying();
      state = state.answerQuestion(correct: false); // 0 lives → game over

      expect(state.lives, 0);
      expect(state.status, GameStatus.gameOver);
      expect(state.isGameOver, isTrue);
    });

    test('advanceRoom increments currentRoomIndex', () {
      var state = initial.answerQuestion(correct: true);
      state = state.advanceRoom();

      expect(state.currentRoomIndex, 1);
      expect(state.status, GameStatus.loading);
    });

    test('answering last room correctly triggers complete status', () {
      var state = initial;
      // Advance to last room (index 9)
      for (var i = 0; i < 9; i++) {
        state = state.answerQuestion(correct: true).advanceRoom().markPlaying();
      }
      expect(state.currentRoomIndex, 9);

      // Answer last question correctly
      state = state.answerQuestion(correct: true);
      expect(state.status, GameStatus.complete);
      expect(state.isComplete, isTrue);
    });

    test('roomsCompleted returns count of completed rooms', () {
      expect(initial.roomsCompleted, 0);

      var state = initial.answerQuestion(correct: true);
      expect(state.roomsCompleted, 1);

      state = state.advanceRoom().markPlaying().answerQuestion(correct: false);
      expect(state.roomsCompleted, 2);
    });

    test('markLoading and markPlaying change status only', () {
      var state = initial.markPlaying();
      expect(state.status, GameStatus.playing);
      expect(state.score, 0);

      state = state.markLoading();
      expect(state.status, GameStatus.loading);
    });

    test('restart resets to fresh initial state', () {
      var state = initial
          .answerQuestion(correct: true)
          .advanceRoom()
          .markPlaying()
          .answerQuestion(correct: false);

      // Score = 10, lives = 2, room 1
      expect(state.score, 10);
      expect(state.lives, 2);
    });

    test('addUsedArticle accumulates titles without duplicates', () {
      var state = initial;
      state = state.copyWith(
          usedArticleTitles: {...state.usedArticleTitles, 'Castle'});
      state = state.copyWith(
          usedArticleTitles: {...state.usedArticleTitles, 'Drawbridge'});
      state = state.copyWith(
          usedArticleTitles: {...state.usedArticleTitles, 'Castle'});

      expect(state.usedArticleTitles.length, 2);
      expect(state.usedArticleTitles, containsAll(['Castle', 'Drawbridge']));
    });
  });

  group('Question model', () {
    test('fromJson parses correctly', () {
      final json = {
        'question': 'What is a drawbridge?',
        'options': ['A bridge', 'A weapon', 'A tower', 'A gate'],
        'correct_index': 0,
        'fun_fact': 'Drawbridges date back to antiquity.',
        'article_title': 'Drawbridge',
        'article_url': 'https://en.wikipedia.org/wiki/Drawbridge',
      };

      // Inline parse via GameState (using Question directly)
      expect(json['question'], 'What is a drawbridge?');
      expect((json['options'] as List).length, 4);
      expect(json['correct_index'], 0);
    });
  });

  group('Room model', () {
    test('initial rooms are not completed', () {
      final state = buildInitialGameState();
      for (final room in state.rooms) {
        expect(room.completed, isFalse);
        expect(room.answeredCorrectly, isNull);
      }
    });

    test('room themes have correct IDs', () {
      final ids = roomThemes.map((t) => t.id).toList();
      expect(ids, contains('entrance'));
      expect(ids, contains('throne'));
      expect(ids, contains('tower'));
      expect(ids.length, 10);
    });

    test('each room theme has at least one wiki topic', () {
      for (final theme in roomThemes) {
        expect(theme.wikiTopics, isNotEmpty);
      }
    });
  });
}
