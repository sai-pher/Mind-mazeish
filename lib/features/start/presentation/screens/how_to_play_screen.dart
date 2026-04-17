import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.stoneDark,
        title: const Text('How to Play'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: const [
              _HeroCard(),
              SizedBox(height: 16),
              _Section(
                icon: Icons.favorite,
                title: 'Lives',
                body:
                    'You start every Standard game with 3 ❤️ lives. Each wrong answer '
                    'costs one life. Lose all three and the quest ends. In Endless mode '
                    'you still start with 3 lives but there is no question limit — play '
                    'until the dungeon claims you.',
              ),
              _Section(
                icon: Icons.military_tech,
                title: 'Scoring',
                body:
                    'Every correct answer earns points. The exact value scales with the '
                    'question difficulty: easy answers earn fewer points, hard ones earn '
                    'more. Your total score is shown in the top-right corner during play '
                    'and saved to your stats after the game.',
              ),
              _Section(
                icon: Icons.local_fire_department,
                title: 'Streaks & Rewards',
                body:
                    'Answer correctly several times in a row to build a streak 🔥 '
                    '(Endless mode only). When your streak hits the limit for the '
                    'current difficulty, you earn a reward:\n\n'
                    '• If you have fewer than 3 lives → one life is restored ❤️\n'
                    '• If you already have 3 lives → bonus points are awarded ⚡',
              ),
              _Section(
                icon: Icons.tune,
                title: 'Game Modes',
                body:
                    'Standard mode gives you 10 questions across your chosen topics. '
                    'Complete all 10 without losing your last life to win.\n\n'
                    'Endless mode keeps going until your lives run out. Your high score '
                    'is tracked separately and shown on the results screen.',
              ),
              _Section(
                icon: Icons.menu_book,
                title: 'Wikipedia Links',
                body:
                    'Each question is linked to a Wikipedia article. Tap the 📖 icon '
                    'on the question card to read it before answering.\n\n'
                    'After you answer, the fun-fact sheet also shows a "Read Article" '
                    'button so you can dive deeper before moving on.',
              ),
              _Section(
                icon: Icons.book_outlined,
                title: 'Notebook',
                body:
                    'Every Wikipedia article you open is saved to your Notebook. '
                    'Access it from the start screen to revisit articles from past '
                    'games — great for exploring topics you found interesting.',
              ),
              _Section(
                icon: Icons.stars,
                title: 'Stars & Results',
                body:
                    'At the end of a Standard game you earn 1–3 stars based on your '
                    'score and accuracy:\n\n'
                    '⭐⭐⭐ — All questions correct and high score\n'
                    '⭐⭐ — At least 60 % answered, decent score\n'
                    '⭐ — Any score above 10\n\n'
                    'Endless mode shows your personal best instead of stars.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero card
// ---------------------------------------------------------------------------

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.torchAmber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏰', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Welcome to the Dungeon',
                  style: tt.displaySmall?.copyWith(
                      color: AppColors.torchAmber, fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Mind Mazeish is a trivia game set in a medieval castle. '
            'Answer questions to advance through rooms, survive on lives, '
            'and discover the Wikipedia articles behind every question.',
            style: tt.labelMedium?.copyWith(
                color: AppColors.textLight.withValues(alpha: 0.85), height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section card
// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Section({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.stone.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.stoneMid),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.torchAmber, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: tt.labelLarge?.copyWith(
                      color: AppColors.torchAmber, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: tt.labelMedium?.copyWith(
                  color: AppColors.textLight.withValues(alpha: 0.85),
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
