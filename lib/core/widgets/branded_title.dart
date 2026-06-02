import 'package:flutter/material.dart';

class BrandedTitle extends StatelessWidget {
  const BrandedTitle({
    super.key,
    required this.label,
    this.logoSize = 20,
    this.spacing = 8,
    this.style,
    this.showLogo = false,
  });

  final String label;
  final double logoSize;
  final double spacing;
  final TextStyle? style;
  final bool showLogo;

  static const _logoAssetPath = 'assets/images/logo/app_logo.png';

  @override
  Widget build(BuildContext context) {
    if (!showLogo) {
      return Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            _logoAssetPath,
            width: logoSize,
            height: logoSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.account_balance_wallet_rounded,
                size: logoSize,
                color: Theme.of(context).colorScheme.primary,
              );
            },
          ),
        ),
        SizedBox(width: spacing),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}
