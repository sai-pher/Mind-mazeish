import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class RoomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String roomName;
  final int score;
  final int lives;

  const RoomHeader({
    super.key,
    required this.roomName,
    required this.score,
    required this.lives,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      title: Text(roomName),
      actions: [
        // Lives
        Row(
          children: List.generate(
            3,
            (i) => Icon(
              Icons.favorite,
              size: 18,
              color: i < lives ? AppColors.dangerRed : AppColors.stoneMid,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Score pill
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.stoneDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.torchAmber, width: 1),
          ),
          child: Text(
            '$score',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.torchAmber,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
