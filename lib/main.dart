import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:eventsphere/Authenticate/authwrapper.dart';
import 'firebase_options.dart';
import 'package:eventsphere/pages/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';

class GlobalTimerService {
  static Timer? _timer;

  static void start() {
    const duration = Duration(seconds: 30);
    NotificationService.checkAndScheduleNotifications();

    _timer = Timer.periodic(duration, (Timer t) {
      print("Timer ticked at ${DateTime.now()}");
      NotificationService.checkAndScheduleNotifications();
    });
    print("Global timer started at ${DateTime.now()}");
  }

  static void stop() {
    _timer?.cancel();
    print("Global timer stopped at ${DateTime.now()}");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Initializing Firebase...');
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    print('Firebase initialized successfully.');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    return;
  }
  print('Initializing Notifications...');
  NotificationService.initialize();

  print('Initializing Timezones...');
  tz.initializeTimeZones();
  print('Current Time Zone: ${tz.local}');
  runApp(const MyApp());

  GlobalTimerService.start();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'EventSphere',
      home: AuthWrapper(),
    );
  }
}
