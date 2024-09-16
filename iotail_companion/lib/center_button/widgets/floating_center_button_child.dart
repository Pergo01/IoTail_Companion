import 'package:flutter/material.dart';

import '../constants/dimens.dart';
import 'animated_button.dart';
import '../util/event_bus.dart';

class FloatingCenterButtonChild extends StatelessWidget {
  const FloatingCenterButtonChild({required this.child, this.onTap, super.key});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AnimatedButtonState.eventBus.sendEvent(ItemClickBusEvent());
        onTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.all(Dimens.buttonContentPadding),
        child: CircleAvatar(
          backgroundColor:
              Colors.white.withOpacity(Dimens.buttonContentOpacityValue),
          radius: Dimens.circularButtonContentRadius,
          child: child,
        ),
      ),
    );
  }
}
