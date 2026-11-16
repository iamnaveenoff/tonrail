import 'package:flutter/material.dart';

import '../device/headset_controller.dart';

class HeadsetScope extends InheritedNotifier<HeadsetController> {
  const HeadsetScope({super.key, required HeadsetController controller, required super.child})
    : super(notifier: controller);

  static HeadsetController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HeadsetScope>()!.notifier!;

  static HeadsetController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<HeadsetScope>()!.notifier!;
}
