import 'package:flutter/material.dart';

class TvFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool autoFocus;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final Color focusedBorderColor;
  final Color? normalBackgroundColor;
  final Color? focusedBackgroundColor;

  const TvFocusable({
    super.key,
    required this.child,
    this.onPressed,
    this.focusNode,
    this.autoFocus = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.padding = EdgeInsets.zero,
    this.focusedBorderColor = const Color(0xFF3B82F6),
    this.normalBackgroundColor,
    this.focusedBackgroundColor,
  });

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  late FocusNode _effectiveFocusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode = widget.focusNode ?? FocusNode();
    _effectiveFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _effectiveFocusNode.dispose();
    } else {
      _effectiveFocusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });

      if (_isFocused) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Focus(
      focusNode: _effectiveFocusNode,
      autofocus: widget.autoFocus,
      onKeyEvent: (node, event) {
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          transform: _isFocused ? Matrix4.diagonal3Values(1.04, 1.04, 1.0) : Matrix4.identity(),
          transformAlignment: Alignment.center,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _isFocused
                ? (widget.focusedBackgroundColor ??
                      colors.primary.withValues(alpha: 0.18))
                : (widget.normalBackgroundColor ?? Colors.transparent),
            borderRadius: widget.borderRadius,
            border: Border.all(
              color: _isFocused ? widget.focusedBorderColor : Colors.transparent,
              width: _isFocused ? 3.0 : 0.0,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: widget.focusedBorderColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
