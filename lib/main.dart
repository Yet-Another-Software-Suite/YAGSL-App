import 'package:flutter/material.dart';
import 'package:yagsl_app/DataController.dart';
import 'package:yagsl_app/home_page.dart';
import 'package:provider/provider.dart';
import 'package:yagsl_app/services/log_store.dart';
import 'package:yagsl_app/services/robot_connection_manager.dart';
import 'package:yagsl_app/settings_controller.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DataController()..load()),
        ChangeNotifierProvider(create: (context) => LogStore()),
        Provider(
          create: (context) {
            final dataController = context.read<DataController>();
            return RobotConnectionManager(
              nt4StatusUpdater: dataController.setNt4Status,
            );
          },
        ),
        ChangeNotifierProvider(
          create: (context) => SettingsController()..load(),
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          final lightScheme = ColorScheme.fromSeed(
            seedColor: const Color(0xff2f7a1f),
          );
          final darkScheme = ColorScheme.fromSeed(
            seedColor: const Color(0xff2f7a1f),
            brightness: Brightness.dark,
          );

          return MaterialApp(
            title: 'YAGSL Configurator',
            theme: ThemeData(
                useMaterial3: true,
                colorScheme: lightScheme,
                scaffoldBackgroundColor: const Color(0xfff4f8f2),
                appBarTheme: const AppBarTheme(
                  centerTitle: false,
                  surfaceTintColor: Colors.transparent,
                ),
                inputDecorationTheme: const InputDecorationTheme(
                  filled: true,
                  fillColor: Color(0xffeef5ea),
                  border: OutlineInputBorder(),
                ),
                cardTheme: CardThemeData(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                navigationBarTheme: NavigationBarThemeData(
                  height: 72,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  indicatorColor: lightScheme.primaryContainer,
                ),
                listTileTheme: const ListTileThemeData(
                  dense: true,
                )),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: darkScheme,
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                surfaceTintColor: Colors.transparent,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white10,
                border: const OutlineInputBorder(),
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              navigationBarTheme: const NavigationBarThemeData(
                height: 72,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              ),
              listTileTheme: const ListTileThemeData(
                dense: true,
              ),
            ),
            themeMode: settings.themeMode,
            debugShowCheckedModeBanner: false,
            home: HomePage(),
          );
        },
      ),
    );
  }
}
