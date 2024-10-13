import 'package:flutter/material.dart';
import 'friend_list_screen.dart';

void main() => runApp(const FriendshipTracker());

class FriendshipTracker extends StatelessWidget {
  const FriendshipTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Friendship Tracker',
      home: FriendListScreen(),
    );
  }
}
