import 'package:flutter/material.dart';

import '../widgets/floating_center_button.dart';
import '../widgets/floating_center_button_child.dart';

/// [BottomBarCenterModel] class is model class for bottom menu.
/// It takes [icon], [iconSelected], [title], [dotColor], [titleStyle] as parameters.
class BottomBarCenterModel {
  const BottomBarCenterModel({
    required this.centerIcon,
    required this.centerIconChild,
    this.centerBackgroundColor = Colors.orange,
  });

  final FloatingCenterButton centerIcon;
  final Color centerBackgroundColor;
  final List<FloatingCenterButtonChild> centerIconChild;
}
