import 'package:flutter/material.dart';

import '../constants/dimens.dart';

/// [FloatingCenterButton] class shows a
class FloatingCenterButton extends StatefulWidget {
  const FloatingCenterButton(
      {required this.child, this.onAnimationComplete, Key? key})
      : super(key: key);
  final Widget child;
  final VoidCallback? onAnimationComplete;

  @override
  State<FloatingCenterButton> createState() => FloatingCenterButtonState();
}

class FloatingCenterButtonState extends State<FloatingCenterButton>
    with TickerProviderStateMixin {
  late AnimationController animationController;

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RotationTransition(
        turns: Tween(begin: 0.0, end: 1.0).animate(animationController),
        child: widget.child,
      ),
    );
  }

  void _initialize() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: Dimens.animationDurationHigh),
      vsync: this,
      upperBound: 0.5,
    );
    animationController.addListener(() {
      if (animationController.isCompleted) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  void reverseAnimation() {
    animationController.reverse(from: .5);
  }

  void forwardAnimation() {
    animationController.forward(from: .0);
  }
}
