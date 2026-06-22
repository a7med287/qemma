import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qemma/features/student/data/repositories/student_repository.dart';
import 'package:qemma/features/student/presentation/routes/student_routes.dart';
import 'package:qemma/features/teacher/presentation/views/teacher_dashboard_view.dart';

import 'constants.dart';
import 'core/cubits/theme_cubit/theme_cubit.dart';
import 'core/cubits/theme_cubit/theme_state.dart';
import 'core/network/api_client.dart';
import 'core/services/shared_preferences_singleton.dart';
import 'core/utils/app_theme.dart';
import 'core/widgets/main_view.dart';
import 'features/auth/data/services/auth_service.dart';
import 'features/auth/presentation/cubits/auth_cubit.dart';
import 'features/auth/presentation/views/login_view.dart';
import 'features/auth/presentation/views/register_view.dart';
import 'features/on_boarding/presentation/views/on_boarding_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.init();

  final apiClient = ApiClient();
  await apiClient.initToken();

  runApp(QemmaApp(apiClient: apiClient));
}

class QemmaApp extends StatelessWidget {
  const QemmaApp({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>.value(value: apiClient),
        RepositoryProvider(create: (_) => AuthService(apiClient)),
        RepositoryProvider(create: (_) => StudentRepository(apiClient)),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(create: (context) => AuthCubit(context.read<AuthService>())),
        ],
        child: const _QemaAppView(),
      ),
    );
  }
}

class _QemaAppView extends StatelessWidget {
  const _QemaAppView();

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, state) {
            return MaterialApp(
              title: 'Qemma',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: state.themeMode,
              useInheritedMediaQuery: true,
              locale: DevicePreview.locale(context),
              builder: (context, child) {
                child = DevicePreview.appBuilder(context, child);
                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: child,
                );
              },
              initialRoute: Prefs.getBool(kIsOnBoardingSeen)
                  ? LoginView.routeName
                  : OnBoardingView.routeName,
              routes: {
                OnBoardingView.routeName: (_) => const OnBoardingView(),
                LoginView.routeName: (_) => const LoginView(),
                RegisterView.routeName: (_) => const RegisterView(),
                MainView.routeName: (_) => const MainView(),
                ...StudentRoutes.routes,
                TeacherDashboardView.routeName: (_) => const TeacherDashboardView(),
              },
              onGenerateRoute: StudentRoutes.onGenerateRoute,
            );
          },
        );
      },
    );
  }
}
