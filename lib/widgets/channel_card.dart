import 'package:flutter/material.dart';

import '../models/channel.dart';
import '../theme/app_theme.dart';
import 'tv_focusable.dart';

class ChannelCard extends StatelessWidget {
  final Channel channel;
  final int? channelNumber;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final FocusNode? focusNode;

  const ChannelCard({
    super.key,
    required this.channel,
    this.channelNumber,
    required this.onTap,
    required this.onFavoriteToggle,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TvFocusable(
      focusNode: focusNode,
      onPressed: onTap,
      normalBackgroundColor: context.appCard,
      focusedBackgroundColor: colors.primary.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 176,
        height: 164,
        child: Container(
          decoration: BoxDecoration(
            color: context.appCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.appSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: channel.tvgLogo != null &&
                                channel.tvgLogo!.trim().isNotEmpty
                            ? Image.network(
                                channel.tvgLogo!.trim(),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.tv_rounded,
                                      size: 42,
                                      color: colors.onSurfaceVariant,
                                    ),
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) {
                                        return child;
                                      }
                                      return Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: colors.primary,
                                          ),
                                        ),
                                      );
                                    },
                              )
                            : Icon(
                                Icons.tv_rounded,
                                size: 42,
                                color: colors.onSurfaceVariant,
                              ),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Material(
                        color: context.appCard.withValues(alpha: 0.88),
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: onFavoriteToggle,
                          icon: Icon(
                            channel.isFavorite
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: channel.isFavorite
                                ? AppTheme.favoriteGold
                                : colors.onSurfaceVariant,
                            size: 21,
                          ),
                          tooltip: channel.isFavorite
                              ? 'Remove from Favorites'
                              : 'Add to Favorites',
                          constraints: const BoxConstraints.tightFor(
                            width: 36,
                            height: 36,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      channelNumber == null
                          ? channel.groupTitle
                          : 'Channel $channelNumber',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
