import 'package:budget/functions.dart';
import 'package:budget/pages/accountsPage.dart';
import 'package:budget/pages/autoTransactionsPageEmail.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/iconObjects.dart';
import 'package:budget/struct/keyboardIntents.dart';
import 'package:budget/struct/logging.dart';
import 'package:budget/widgets/fadeIn.dart';
import 'package:budget/struct/languageMap.dart';
import 'package:budget/struct/initializeBiometrics.dart';
import 'package:budget/widgets/util/appLinks.dart';
import 'package:budget/widgets/util/onAppResume.dart';
import 'package:budget/widgets/util/watchForDayChange.dart';
import 'package:budget/widgets/watchAllWallets.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/database/updateWalletCurrencyToINR.dart';
import 'package:budget/database/reduceTransactionsForTesting.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/notificationsGlobal.dart';
import 'package:budget/widgets/navigationSidebar.dart';
import 'package:budget/widgets/globalLoadingProgress.dart';
import 'package:budget/struct/scrollBehaviorOverride.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/struct/initializeNotifications.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:budget/widgets/restartApp.dart';
import 'package:budget/struct/customDelayedCurve.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:budget/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:device_preview/device_preview.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'ai/services/ai_engine.dart';

// Requires hot restart when changed
bool enableDevicePreview = false && kDebugMode;
bool allowDebugFlags = true || kIsWeb;
bool allowDangerousDebugFlags = kDebugMode;

void main() async {
  try {
    await _initializeApp();
  } catch (e, stackTrace) {
    debugPrint('CRITICAL ERROR during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    // Still try to run the app even if initialization partially failed
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text('App initialization error'),
                SizedBox(height: 8),
                Text('$e', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _initializeApp() async {
  captureLogs(() async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Starting app initialization...');
    
    // Load environment variables (e.g. GEMINI_API_KEY from .env)
    // Wrap in try-catch to prevent app crash if .env file is missing
    try {
      // Try loading from root first (for development), then from assets
      try {
        await dotenv.load(fileName: '.env').timeout(Duration(seconds: 3));
        debugPrint('Successfully loaded .env file from root');
      } catch (_) {
        // If root fails, try loading from assets (for mobile builds)
        try {
          await dotenv.load(fileName: 'assets/.env').timeout(Duration(seconds: 3));
          debugPrint('Successfully loaded .env file from assets');
        } catch (_) {
          debugPrint('Could not load .env from either location');
        }
      }
    } catch (e) {
      debugPrint('Warning: Could not load .env file: $e');
      // Continue without .env - AI features will be disabled
    }
    
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(Duration(seconds: 10), onTimeout: () {
      debugPrint('Firebase initialization timed out');
      throw TimeoutException('Firebase initialization timed out');
    });
    debugPrint('Firebase initialized');
    
    debugPrint('Initializing EasyLocalization...');
    await EasyLocalization.ensureInitialized().timeout(Duration(seconds: 5));
    debugPrint('EasyLocalization initialized');
    
    debugPrint('Getting SharedPreferences...');
    sharedPreferences = await SharedPreferences.getInstance().timeout(Duration(seconds: 5));
    debugPrint('SharedPreferences loaded');
    
    debugPrint('Constructing database...');
    database = await constructDb('db').timeout(Duration(seconds: 10));
    debugPrint('Database constructed');
    
    // Convert all USD wallets to INR
    try {
      await updateAllWalletsToINR();
    } catch (e) {
      debugPrint('Warning: Could not update wallets to INR: $e');
    }
    
    // Reduce transactions to last 20 for easier AI verification
    try {
      await reduceTransactionsForTesting(keepCount: 20);
      debugPrint('✅ Transaction reduction completed - keeping last 20 transactions for AI testing');
    } catch (e) {
      debugPrint('Warning: Could not reduce transactions: $e');
    }
    
    debugPrint('Initializing notifications...');
    notificationPayload = await initializeNotifications().timeout(Duration(seconds: 5));
    debugPrint('Notifications initialized');
    
    entireAppLoaded = false;
    
    debugPrint('Loading currency JSON...');
    await loadCurrencyJSON().timeout(Duration(seconds: 5));
    debugPrint('Currency JSON loaded');
    
    debugPrint('Loading language names JSON...');
    await loadLanguageNamesJSON().timeout(Duration(seconds: 5));
    debugPrint('Language names JSON loaded');
    
    debugPrint('Initializing settings...');
    await initializeSettings().timeout(Duration(seconds: 5));
    debugPrint('Settings initialized');
    tz.initializeTimeZones();
    // Add timeout to prevent hanging on timezone detection
    try {
      final String locationName = await FlutterTimezone.getLocalTimezone()
          .timeout(Duration(seconds: 5), onTimeout: () {
        debugPrint('Timezone detection timed out, using default');
        return "America/New_York";
      });
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (e) {
      debugPrint('Error getting timezone: $e, using default');
      tz.setLocalLocation(tz.getLocation("America/New_York"));
    }
    debugPrint('Sorting icon objects...');
    iconObjects.sort((a, b) => (a.mostLikelyCategoryName ?? a.icon)
        .compareTo((b.mostLikelyCategoryName ?? b.icon)));
    debugPrint('Icon objects sorted');

    // Configure AI engine - Prioritizes Groq (free, no quota issues), falls back to Gemini
    try {
      // Check for Groq API key first (recommended - free, no setup issues)
      final groqKey = dotenv.env['GROQ_API_KEY']?.trim();
      if (groqKey != null && groqKey.isNotEmpty) {
        String cleanKey = groqKey;
        if ((cleanKey.startsWith('"') && cleanKey.endsWith('"')) ||
            (cleanKey.startsWith("'") && cleanKey.endsWith("'"))) {
          cleanKey = cleanKey.substring(1, cleanKey.length - 1);
        }
        debugPrint('✅ Groq API key found in .env, configuring AIEngine with Groq');
        AIEngine().configure(apiKey: cleanKey, providerType: AIProviderType.groq);
        debugPrint('✅ AIEngine configured with Groq. isConfigured: ${AIEngine().isConfigured}');
      } else {
        // Only check Gemini if Groq key is not found
        debugPrint('⚠️ Groq API key not found, checking for Gemini API key...');
        final geminiKey = dotenv.env['GEMINI_API_KEY']?.trim();
        
        if (geminiKey != null && geminiKey.isNotEmpty) {
          String cleanKey = geminiKey;
          if ((cleanKey.startsWith('"') && cleanKey.endsWith('"')) ||
              (cleanKey.startsWith("'") && cleanKey.endsWith("'"))) {
            cleanKey = cleanKey.substring(1, cleanKey.length - 1);
          }
          debugPrint('✅ Gemini API key found in .env, configuring AIEngine with Gemini');
          AIEngine().configure(apiKey: cleanKey, providerType: AIProviderType.gemini);
          debugPrint('✅ AIEngine configured with Gemini. isConfigured: ${AIEngine().isConfigured}');
        } else {
          debugPrint('❌ No AI API key found in .env file');
          debugPrint('💡 Add GROQ_API_KEY (recommended) or GEMINI_API_KEY to .env');
          debugPrint('📋 Available env keys: ${dotenv.env.keys.toList()}');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error configuring AI engine: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    
    debugPrint('Setting high refresh rate...');
    setHighRefreshRate();
    debugPrint('High refresh rate set');
    
    debugPrint('Calling runApp...');
    runApp(
      DevicePreview(
        enabled: enableDevicePreview,
        builder: (context) => InitializeLocalizations(
          child: RestartApp(
            child: InitializeApp(key: appStateKey),
          ),
        ),
      ),
    );
    debugPrint('runApp called successfully');
  });
}

GlobalKey<_InitializeAppState> appStateKey = GlobalKey();
GlobalKey<PageNavigationFrameworkState> pageNavigationFrameworkKey =
    GlobalKey();

class InitializeApp extends StatefulWidget {
  InitializeApp({Key? key}) : super(key: key);

  @override
  State<InitializeApp> createState() => _InitializeAppState();
}

class _InitializeAppState extends State<InitializeApp> {
  void refreshAppState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return App(key: ValueKey("Main App"));
  }
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("Rebuilt Material App");
    return MaterialApp(
      showPerformanceOverlay: kProfileMode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale:
          enableDevicePreview ? DevicePreview.locale(context) : context.locale,
      shortcuts: shortcuts,
      actions: keyboardIntents,
      themeAnimationDuration: Duration(milliseconds: 400),
      themeAnimationCurve: CustomDelayedCurve(),
      key: ValueKey('CashewAppMain'),
      title: 'Cashew',
      theme: getLightTheme(),
      darkTheme: getDarkTheme(),
      scrollBehavior: ScrollBehaviorOverride(),
      themeMode: getSettingConstants(appStateSettings)["theme"],
      home: HandleWillPopScope(
        child: Stack(
          children: [
            Row(
              children: [
                NavigationSidebar(key: sidebarStateKey),
                Expanded(
                    child: Stack(
                  children: [
                    InitialPageRouteNavigator(),
                    GlobalSnackbar(key: snackbarKey),
                  ],
                )),
              ],
            ),
            EnableSignInWithGoogleFlyIn(),
            GlobalLoadingIndeterminate(key: loadingIndeterminateKey),
            GlobalLoadingProgress(key: loadingProgressKey),
          ],
        ),
      ),
      builder: (context, child) {
        if (kReleaseMode) {
          ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
            return Container(color: Colors.transparent);
          };
        }

        Widget mainWidget = OnAppResume(
          updateGlobalAppLifecycleState: true,
          onAppResume: () async {
            await setHighRefreshRate();
          },
          child: InitializeBiometrics(
            child: InitializeNotificationService(
              child: InitializeAppLinks(
                child: WatchForDayChange(
                  child: WatchSelectedWalletPk(
                    child: WatchAllWallets(
                      child: child ?? SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        if (kIsWeb) {
          return FadeIn(
              duration: Duration(milliseconds: 1000), child: mainWidget);
        } else {
          return mainWidget;
        }
      },
      // ),
    );
  }
}
