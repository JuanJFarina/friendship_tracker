import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'friend_list_screen.dart';
import 'color_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  runApp(const FriendshipTracker());
}

class FriendshipTracker extends StatelessWidget {
  const FriendshipTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Friendship Tracker',
      theme: ThemeData(
        scaffoldBackgroundColor: plainWhite,
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: commonGrey,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            color: commonGrey,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: plainWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: yellowAlert,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: blueAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: blueAccent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: plainWhite,
          ),
        ),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        ),
      ),
      home: FriendListScreen(),
    );
  }
}
