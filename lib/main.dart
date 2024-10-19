import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'friend_list_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );

  runApp(const FriendshipTracker());
}

class FriendshipTracker extends StatelessWidget {
  const FriendshipTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Friendship Tracker',
      theme: ThemeData(
        // Use a soft, neutral background color
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),

        // Define the text theme with a friendly, rounded font and a simple hierarchy
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            color: Color(0xFF666666),
          ),
          labelLarge: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Rounded buttons with accent color and soft shadows
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFA726), // Accent orange color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Rounded corners
            ),
            elevation: 2, // Soft shadow
          ),
        ),

        // Floating action button to follow the minimalist, rounded theme
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF29B6F6), // Friendly blue accent color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),

        // Define app bar style to keep it simple and minimalist
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF29B6F6), // Use the same blue accent
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        // Rounded corners and slight shadows for cards
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        ),
      ),
      home: const FriendListScreen(),
    );
  }
}
