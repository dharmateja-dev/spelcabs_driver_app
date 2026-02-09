import 'package:country_code_picker/country_code_picker.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/controller/global_setting_conroller.dart';
import 'package:driver/firebase_options.dart';
import 'package:driver/ui/splash_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'dart:developer';

import 'services/localization_service.dart';
import 'themes/Styles.dart';
import 'utils/Preferences.dart';
import 'services/city_rides_listener_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    name: "Driver",
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Preferences.initPref();

  // Initialize date formatting safely
  try {
    await initializeDateFormatting();
    Intl.defaultLocale = 'en';
  } catch (e) {
    log('Date formatting error: $e');
  }

  // Initialize city rides notification listener
  await CityRidesListenerService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getCurrentAppTheme();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    getCurrentAppTheme();
  }

  @override
  void didChangePlatformBrightness() {
    themeChangeProvider.updateSystemTheme();
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme =
        await themeChangeProvider.darkThemePreference.getTheme();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        return themeChangeProvider;
      },
      child: Consumer<DarkThemeProvider>(builder: (context, value, child) {
        return GetMaterialApp(
          title: 'Spelcabs',
          debugShowCheckedModeBanner: false,
          themeMode: themeChangeProvider.darkTheme == 0
              ? ThemeMode.dark
              : themeChangeProvider.darkTheme == 1
                  ? ThemeMode.light
                  : ThemeMode.system,
          theme: Styles.themeData(false, context),
          darkTheme: Styles.themeData(true, context),
          localizationsDelegates: const [
            CountryLocalizations.delegate,
          ],
          locale: const Locale('en'), // HARDCODED - no dynamic changes
          fallbackLocale: const Locale('en'),
          translations: LocalizationService(),
          builder: EasyLoading.init(),
          home: const AppInitializer(),
        );
      }),
    );
  }
}

// NEW: Separate widget for initialization
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final GlobalSettingController _controller =
      Get.put(GlobalSettingController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_controller.isLoading.value) {
        return Constant.loader(context);
      }
      return const SplashScreen();
    });
  }
}
