import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/theme.dart';

class GoogleAvatar extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final double size;
  final double borderWidth;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  const GoogleAvatar({
    super.key,
    required this.photoUrl,
    required this.displayName,
    this.size = 38,
    this.borderWidth = 0,
    this.borderColor,
    this.boxShadow,
  });

  Widget _buildFallbackLetter(double fontSize) {
    final letter = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : 'G';
    return Container(
      width: size,
      height: size,
      color: AppTheme.primary.withOpacity(0.15),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = (size * 0.42).clamp(10.0, 26.0);
    final hasValidUrl = photoUrl != null && photoUrl!.trim().isNotEmpty;

    Widget avatarContent;
    if (hasValidUrl) {
      avatarContent = CachedNetworkImage(
        imageUrl: photoUrl!.trim(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 150),
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: AppTheme.surfaceGlass,
          child: Center(
            child: SizedBox(
              width: size * 0.35,
              height: size * 0.35,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackLetter(fontSize),
      );
    } else {
      avatarContent = _buildFallbackLetter(fontSize);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? AppTheme.border,
                width: borderWidth,
              )
            : null,
        boxShadow: boxShadow,
      ),
      child: ClipOval(
        child: avatarContent,
      ),
    );
  }
}
