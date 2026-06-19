import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/app_text.dart';

enum UniversalModalType { info, action }

/// Global modal — all text-only dialogs must use [showInfo] or [showAction].
abstract final class UniversalModal {
  static const _padding = 24.0;
  static const _buttonHeight = 44.0;

  /// Text-only alert with a single primary button. Returns `true` when confirmed.
  static Future<bool> showInfo(
    BuildContext context, {
    String? title,
    required String content,
    String primaryBtnText = '知道了',
    bool closeOnOverlayClick = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: closeOnOverlayClick,
      barrierColor: Colors.transparent,
      builder: (context) => _UniversalModalView(
        type: UniversalModalType.info,
        title: title,
        content: content,
        primaryBtnText: primaryBtnText,
        closeOnOverlayClick: closeOnOverlayClick,
      ),
    );
    return result ?? false;
  }

  /// Interactive dialog with primary + secondary actions.
  /// Returns `true` for primary, `false` for secondary/dismiss.
  static Future<bool> showAction(
    BuildContext context, {
    String? title,
    required String content,
    required String primaryBtnText,
    String secondaryBtnText = '取消',
    bool closeOnOverlayClick = false,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: closeOnOverlayClick,
      barrierColor: Colors.transparent,
      builder: (context) => _UniversalModalView(
        type: UniversalModalType.action,
        title: title,
        content: content,
        primaryBtnText: primaryBtnText,
        secondaryBtnText: secondaryBtnText,
        closeOnOverlayClick: closeOnOverlayClick,
        destructive: destructive,
      ),
    );
    return result ?? false;
  }
}

class _UniversalModalView extends StatelessWidget {
  const _UniversalModalView({
    required this.type,
    this.title,
    required this.content,
    required this.primaryBtnText,
    this.secondaryBtnText,
    this.closeOnOverlayClick = false,
    this.destructive = false,
  });

  final UniversalModalType type;
  final String? title;
  final String content;
  final String primaryBtnText;
  final String? secondaryBtnText;
  final bool closeOnOverlayClick;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formattedTitle = title != null ? AppText.formatMixed(title!) : null;
    final formattedContent = AppText.formatMixed(content);
    final formattedPrimary = AppText.formatMixed(primaryBtnText);
    final formattedSecondary =
        secondaryBtnText != null ? AppText.formatMixed(secondaryBtnText!) : null;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: closeOnOverlayClick ? () => Navigator.of(context).pop(false) : null,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.marginSide),
                padding: const EdgeInsets.all(UniversalModal._padding),
                decoration: BoxDecoration(
                  color: context.appSurfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: context.appOutlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (formattedTitle != null) ...[
                      Text(
                        formattedTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      formattedContent,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    if (type == UniversalModalType.info)
                      _PrimaryButton(
                        label: formattedPrimary,
                        destructive: destructive,
                        onPressed: () => Navigator.of(context).pop(true),
                      )
                    else
                      Row(
                        children: [
                          if (formattedSecondary != null)
                            Expanded(
                              child: _SecondaryButton(
                                label: formattedSecondary,
                                onPressed: () => Navigator.of(context).pop(false),
                              ),
                            ),
                          if (formattedSecondary != null) const SizedBox(width: 12),
                          Expanded(
                            child: _PrimaryButton(
                              label: formattedPrimary,
                              destructive: destructive,
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final bg = destructive ? AppColors.systemRed : context.appPrimary;
    final fg = destructive ? Colors.white : context.appOnPrimary;

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: const Size(0, UniversalModal._buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      child: Text(label),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, UniversalModal._buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      child: Text(label),
    );
  }
}
