import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qemma/features/auth/presentation/views/login_view.dart';
import 'package:qemma/features/dashboard/presentation/views/dashboard_view.dart';
import 'package:qemma/features/exam_generator/presentation/views/exam_generation_screen.dart';
import 'package:qemma/features/home/presentation/views/home_view.dart';

import 'generated/l10n.dart';

void main() {
  runApp(
    DevicePreview(enabled: !kReleaseMode, builder: (context) => QemmaApp()),
  );
}

class QemmaApp extends StatelessWidget {
  const QemmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: Locale("ar"),
      home: DashboardView(),
    );
  }
}
