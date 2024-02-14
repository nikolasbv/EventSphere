import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static final Set<int> _scheduledNotificationIDs = Set<int>();

  static void initialize() {
    final InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('icon'), 
    );
    _notificationsPlugin.initialize(initializationSettings);
    print('Notifications initialized');
    print('Notification Service Initialize Method Called');
  }

  
static Future<void> checkAndScheduleNotifications() async {
    print('Checking and scheduling notifications');
    
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    print('User UID: $userUid');
    
    var userDoc = await FirebaseFirestore.instance.collection('Users').doc(userUid).get();
    List<dynamic> userEvents = userDoc.data()?['myEvents'] ?? [];
    List<dynamic> homeEvents = userDoc.data()?['homeEvents'] ?? [];
    String username = userDoc.data()?['username'] ?? 'User'; 
    print('User events: $userEvents');

    DateTime now = DateTime.now().toUtc();

    for (var eventId in userEvents) {
        var eventDoc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();
        DateTime eventDateTime = (eventDoc.data()?['date'] as Timestamp).toDate();
        String eventName = eventDoc.data()?['title'] ?? 'Event';

        DateTime notificationTime = eventDateTime.subtract(Duration(hours: 1));

        int notificationId = eventId.hashCode;

        if (now.isBefore(eventDateTime) && now.isBefore(notificationTime)) {
            String notificationBody = "$username, don't miss out on your event '$eventName' starting in one hour!";
            scheduleNotification(notificationId, 'Event Reminder', notificationBody, notificationTime);
            _scheduledNotificationIDs.add(notificationId);
        }
        else{
          print('Event is too close or in the past, no need to schedule for event ID: $notificationId');
        }
    }
  int fixedHour = 17; 
  DateTime todayAtFixedHour = DateTime(now.year, now.month, now.day, fixedHour);

  if (homeEvents.isNotEmpty && now.isBefore(todayAtFixedHour)) {
      var firstEventId = homeEvents.first;
      var eventDoc = await FirebaseFirestore.instance.collection('events').doc(firstEventId).get();
      String eventName = eventDoc.data()?['title'] ?? 'Event';

      String notificationBody = "$username, check out the event '$eventName'. We think you might find it interesting!";
      int notificationId = firstEventId.hashCode;

      scheduleNotification(notificationId, 'Event Suggestion', notificationBody, todayAtFixedHour);
      print('Notification scheduled for home event ID: $notificationId');
  } else {
    print('No home events to notify or it\'s past the notification time.');
  }
}

 
  static void scheduleNotification(int id, String title, String body, DateTime scheduledDate) async {
    print('Scheduling notification. ID: $id, Title: $title, Body: $body, Scheduled Date: $scheduledDate');
    var androidDetails = AndroidNotificationDetails(
      'channel_id', 
      'channel_name', 
      importance: Importance.high, 
      priority: Priority.high, 
      icon: 'icon'
    );

    var tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    print('Timezone Scheduled Date: $tzScheduledDate');

    await _notificationsPlugin.zonedSchedule(
      id, 
      title, 
      body, 
      tzScheduledDate, 
      NotificationDetails(android: androidDetails),
      androidAllowWhileIdle: true, 
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    print('Notification scheduled.');
  }


static Future<void> showNotification(int id, String title, String body) async {
    var androidDetails = AndroidNotificationDetails(
      'main_channel', 
      'Main Channel', 
      importance: Importance.max, 
      priority: Priority.high, 
      icon: 'icon', 
    );

    var notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id, 
      title, 
      body, 
      notificationDetails,
    );
  }
}


