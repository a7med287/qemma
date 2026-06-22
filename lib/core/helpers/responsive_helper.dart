import 'package:flutter/widgets.dart';

/// Simple width-based breakpoints used across the app to make layouts
/// *adaptive* (different structure per device class), on top of
/// flutter_screenutil which makes layouts *responsive* (same structure,
/// scaled sizes).
enum DeviceType { mobile, tablet, desktop }

abstract class ResponsiveHelper {
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  /// Cap content width on large screens (tablet/web/desktop) so layouts
  /// don't stretch edge-to-edge.
  static const double maxContentWidth = 720;

  static DeviceType deviceTypeOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= tabletMaxWidth) return DeviceType.desktop;
    if (width >= mobileMaxWidth) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static bool isMobile(BuildContext context) =>
      deviceTypeOf(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      deviceTypeOf(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      deviceTypeOf(context) == DeviceType.desktop;

  /// Number of grid columns to use for card grids (features, steps...).
  static int gridColumns(BuildContext context) {
    switch (deviceTypeOf(context)) {
      case DeviceType.mobile:
        return 2;
      case DeviceType.tablet:
        return 3;
      case DeviceType.desktop:
        return 3;
    }
  }
}
