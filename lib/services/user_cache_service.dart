// import 'dart:async';
// import 'dart:isolate';
//
// import 'package:driver/services/user_data_service.dart';
// import 'package:driver/utils/app_logger.dart';
//
// // OPTIONAL: uncomment + add dependency if you want to use a real background job plugin
// // import 'package:workmanager/workmanager.dart';
//
// /// Choose strategy depending on needs.
// /// - [timer]: runs periodic Timer on main isolate. Best for network calls that are not CPU-heavy.
// /// - [isolate]: uses `Isolate.run` so the work won't block the main isolate.
// /// - [workmanager]: placeholder -- use platform-specific background job plugin if you need tasks while app is killed.
// enum RefreshStrategy { timer, isolate, workmanager }
//
// class UserCacheService {
//   static RefreshStrategy _strategy = RefreshStrategy.timer;
//   static bool _initialized = false;
//
//   static final Set<String> _activeUserIds = <String>{};
//
//   // Timer strategy state
//   static final Map<String, Timer> _timers = <String, Timer>{};
//
//   // Isolate strategy state
//   // Prevent double-scheduling for same user when using isolate strategy
//   static final Map<String, bool> _isScheduling = <String, bool>{};
//
//   // Interval used for refresh. Change here if you want different frequency.
//   // NOTE: Mobile OS may not allow very frequent background work when app is backgrounded or killed.
//   static Duration refreshInterval = const Duration(minutes: 5);
//
//   /// Initialize the service once. Call this in `main()` before runApp() if you like.
//   static Future<void> init({RefreshStrategy strategy = RefreshStrategy.timer}) async {
//     if (_initialized) return;
//     _initialized = true;
//     _strategy = strategy;
//     AppLogger.debug('UserCacheService initialized with strategy: $_strategy');
//
//     if (_strategy == RefreshStrategy.workmanager) {
//       AppLogger.debug('WorkManager strategy selected. Make sure to configure the plugin in main() per its docs.');
//       // Example (commented):
//       // Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
//       // Workmanager().registerPeriodicTask("refreshUsers", "refreshUserTask", frequency: Duration(minutes: 15));
//       // NOTE: Android supports periodic tasks but minimum reliable interval is typically 15 minutes or more.
//       // iOS does not allow reliable 5-minute periodic execution when app is suspended.
//     }
//   }
//
//   /// Register a user for periodic refresh.
//   /// Call when a user (or a user-related entity) becomes "active" and you want to keep cached data fresh.
//   static void registerUser(String userId) {
//     final added = _activeUserIds.add(userId);
//     if (!added) {
//       AppLogger.debug('UserCacheService: registerUser called but user already registered: $userId');
//       return;
//     }
//
//     AppLogger.debug('UserCacheService: registered user $userId');
//     _startScheduling(userId);
//   }
//
//   /// Unregister a user to stop refreshing their cache.
//   static void unregisterUser(String userId) {
//     final removed = _activeUserIds.remove(userId);
//     if (!removed) return;
//     AppLogger.debug('UserCacheService: unregistered user $userId');
//     _stopScheduling(userId);
//   }
//
//   /// Clean up all resources (timers, state). Call on app dispose if you want.
//   static void dispose() {
//     for (final t in _timers.values) {
//       try {
//         t.cancel();
//       } catch (_) {}
//     }
//     _timers.clear();
//     _activeUserIds.clear();
//     _isScheduling.clear();
//     AppLogger.debug('UserCacheService disposed');
//   }
//
//   static void _startScheduling(String userId) {
//     switch (_strategy) {
//       case RefreshStrategy.timer:
//         _scheduleWithTimer(userId);
//         break;
//       case RefreshStrategy.isolate:
//         _scheduleWithIsolate(userId);
//         break;
//       case RefreshStrategy.workmanager:
//         _scheduleWithWorkManager(userId);
//         break;
//     }
//   }
//
//   static void _stopScheduling(String userId) {
//     // Timer cleanup
//     if (_timers.containsKey(userId)) {
//       try {
//         _timers.remove(userId)?.cancel();
//       } catch (_) {}
//     }
//
//     // Isolate bookkeeping
//     _isScheduling.remove(userId);
//
//     // If using WorkManager, you'd optionally cancel the job here if the plugin supports it.
//   }
//
//   // ---------------------------
//   // Timer-based implementation
//   // ---------------------------
//   static void _scheduleWithTimer(String userId) {
//     // Cancel existing timer just in case
//     _timers[userId]?.cancel();
//
//     // Start periodic timer. We deliberately don't `await` inside timer callback to avoid reentrancy delays.
//     _timers[userId] = Timer.periodic(refreshInterval, (Timer timer) {
//       // Fire-and-forget; internal errors are handled in _runRefresh
//       _runRefresh(userId);
//     });
//
//     // Kick off immediate refresh as well (optional). If you don't want immediate run, remove this.
//     _runRefresh(userId);
//   }
//
//   // ---------------------------
//   // Isolate-based implementation
//   // ---------------------------
//   static void _scheduleWithIsolate(String userId) {
//     // Avoid scheduling duplicated chains for the same user
//     if (_isScheduling[userId] == true) return;
//     _isScheduling[userId] = true;
//
//     // We schedule a delayed loop that uses Isolate.run for the actual work
//     Future<void>.delayed(refreshInterval).then((_) async {
//       try {
//         // Using Isolate.run ensures the callback runs off the main isolate
//         await Isolate.run(() async {
//           await UserDataService.getUser(userId, forceRefresh: true);
//         });
//         AppLogger.debug('Isolate: refreshed user data for $userId');
//       } catch (e, st) {
//         AppLogger.error('Isolate: error refreshing user $userId: $e\n$st');
//       } finally {
//         // continue the chain only if the user is still registered
//         _isScheduling[userId] = false;
//         if (_activeUserIds.contains(userId)) {
//           // schedule next
//           _scheduleWithIsolate(userId);
//         }
//       }
//     });
//   }
//
//   // ---------------------------
//   // WorkManager placeholder
//   // ---------------------------
//   static void _scheduleWithWorkManager(String userId) {
//     // This method is a placeholder. If you want to run tasks when the app is backgrounded/killed,
//     // integrate a background job plugin (e.g. workmanager, android_alarm_manager_plus or a native solution).
//     // NOTE: Android and iOS impose platform limits. iOS will not run reliable 5-minute tasks while the app
//     // is suspended. Android may batch tasks (typical minimum reliable periodic interval is ~15 minutes).
//
//     AppLogger.debug('WorkManager strategy chosen. Please implement platform-specific scheduling.');
//
//     // Example pseudo-code (do not run as-is):
//     // Workmanager().registerOneOffTask('refresh_user_$userId', 'refreshUserTask', inputData: {'userId': userId});
//   }
//
//   // ---------------------------
//   // Shared refresh logic
//   // ---------------------------
//   static Future<void> _runRefresh(String userId) async {
//     try {
//       await UserDataService.getUser(userId, forceRefresh: true);
//       AppLogger.debug('Refreshed user data for: $userId');
//     } catch (e, st) {
//       AppLogger.error('Error refreshing user $userId: $e\n$st');
//     }
//   }
// }
//
// /*
// Usage:
//
// 1) Initialize (in main.dart before runApp):
//
//   void main() async {
//     WidgetsFlutterBinding.ensureInitialized();
//     await UserCacheService.init(strategy: RefreshStrategy.timer); // or isolate/workmanager
//     runApp(const MyApp());
//   }
//
// 2) Register/unregister when user becomes active/inactive:
//
//   UserCacheService.registerUser(userId);
//   // ... later
//   UserCacheService.unregisterUser(userId);
//
// Notes & recommendations:
// - If your refresh is a network call (HTTP) and not CPU-heavy, use the timer strategy. It's reliable while the app is alive and simple.
// - If the refresh is CPU heavy, use the isolate strategy so the main UI thread isn't blocked.
// - If you absolutely need reliable background refresh when the app is killed, implement a platform-specific background worker (WorkManager on Android). iOS cannot guarantee 5-minute intervals — consider server push instead.
// - This file intentionally avoids `worker_manager` to reduce package friction and version mismatches.
// */
