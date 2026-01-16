import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../styles/app_style.dart';

class _Space extends StatelessWidget {
  const _Space(this.width, this.height);
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(width: width, height: height);
}

class VSpace extends StatelessWidget {
  const VSpace(this.size, {super.key});
  final double size;

  @override
  Widget build(BuildContext context) => _Space(0, size.h);

  static VSpace get xs => VSpace(Insets.xs);
  static VSpace get sm => VSpace(Insets.sm);
  static VSpace get md => VSpace(Insets.m);
  static VSpace get lg => VSpace(Insets.l);
  static VSpace get xl => VSpace(Insets.xl);
  static List<VSpace> get bottomOffset => [
        VSpace.xl,
        VSpace.xl,
        VSpace.xl,
      ];
}

class HSpace extends StatelessWidget {
  const HSpace(this.size, {super.key});
  final double size;

  @override
  Widget build(BuildContext context) => _Space(size, 0);

  static HSpace get xs => HSpace(Insets.xs);
  static HSpace get sm => HSpace(Insets.sm);
  static HSpace get md => HSpace(Insets.m);
  static HSpace get lg => HSpace(Insets.l);
  static HSpace get xl => HSpace(Insets.xl);
}
