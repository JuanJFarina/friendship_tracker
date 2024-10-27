import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import 'friend.dart';
import 'friend_list_tile.dart';
import 'utils.dart';
import 'color_constants.dart';

class FriendListScreen extends StatefulWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  FriendListScreen({super.key}) {
    initNotification();
  }

  Future<void> onDidReceiveNotification(
      NotificationResponse notificationResponse) async {}

  Future<void> initNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('friendship_tracker_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotification,
        onDidReceiveBackgroundNotificationResponse: onDidReceiveNotification);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  @override
  // ignore: library_private_types_in_public_api
  _FriendListScreenState createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  List<Friend> friends = [];
  late SharedPreferences prefs;
  bool isExpanded = false;
  bool canSchedule = true;
  int hoursFromLastInteraction = 0;
  String filter = '';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _scheduleTrackFriendsNotification();
    _scheduleNextNotification();
  }

  Future<void> _scheduleTrackFriendsNotification() async {
    await widget.flutterLocalNotificationsPlugin.cancel(1);
    await widget.flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Friendship Tracker',
      "Don't forget to track your interactions with your friends !",
      tz.TZDateTime.now(tz.local).add(Duration(hours: 48)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'friendly_channel_id',
          'Friendly Notification',
          channelDescription:
              'Notification to remind you to check in with your friends',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void _getHoursFromLastInteraction() {
    int hours = 2400;
    for (var friend in friends) {
      if (friend.history.isNotEmpty) {
        DateTime latestInteraction = DateTime.parse(friend.history[0]['date']);
        for (var interaction in friend.history) {
          if (latestInteraction.isBefore(DateTime.parse(interaction['date']))) {
            latestInteraction = DateTime.parse(interaction['date']);
          }
        }
        Duration difference = DateTime.now().difference(latestInteraction);
        if (hours > difference.inHours) {
          hours = difference.inHours;
        }
      }
    }
    hoursFromLastInteraction = hours;
  }

  Future<void> _scheduleNextNotification() async {
    tz.TZDateTime? date;
    String? message;
    bool scheduleNotification = false;
    _getHoursFromLastInteraction();
    if (Utils.isLessThanFourHoursAway(10) && hoursFromLastInteraction >= 24) {
      date = Utils.nextInstanceOfNHour(10);
      message = "Remember to check in with your friends today ! :)";
      scheduleNotification = true;
    } else if (Utils.isLessThanFourHoursAway(18) &&
        hoursFromLastInteraction >= 4 &&
        (DateTime.now().weekday == 5 || DateTime.now().weekday == 6)) {
      date = Utils.nextInstanceOfNHour(18);
      message = "Why not go out with your friends tonight ?";
      scheduleNotification = true;
    } else if (Utils.isLessThanFourHoursAway(22) &&
        hoursFromLastInteraction >= 4 &&
        (DateTime.now().weekday == 5 || DateTime.now().weekday == 6)) {
      date = Utils.nextInstanceOfNHour(22);
      message = "Last chance ! Send a message to your friends and see what they're doing";
      scheduleNotification = true;
    } else {
      canSchedule = true;
    }
    if (scheduleNotification && canSchedule) {
      await widget.flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Friendship Tracker',
        message,
        date!,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'friendly_channel_id',
            'Friendly Notification',
            channelDescription:
                'Notification to remind you to check in with your friends',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      canSchedule = false;
    }
  }

  Future<void> _cancelInteractionNotifications() async {
    await widget.flutterLocalNotificationsPlugin.cancel(0);
  }

  Future<void> _loadFriends() async {
    prefs = await SharedPreferences.getInstance();
    String? friendsJson = prefs.getString('friends');
    if (friendsJson != null) {
      List<dynamic> friendList = jsonDecode(friendsJson);
      setState(() {
        friends = friendList.map((json) => Friend.fromJson(json)).toList();
        _sortFriendsByUpcomingBirthday();
      });
    }
  }

  void _sortFriendsByUpcomingBirthday() {
    DateTime today = DateTime.now();

    friends.sort((a, b) {
      DateTime? nextBirthdayA = Utils.getNextBirthday(a.birthdate, today);
      DateTime? nextBirthdayB = Utils.getNextBirthday(b.birthdate, today);

      if (nextBirthdayA != null && nextBirthdayB != null) {
        return nextBirthdayA.compareTo(nextBirthdayB);
      } else if (nextBirthdayA != null) {
        return -1;
      } else if (nextBirthdayB != null) {
        return 1;
      } else {
        return 0;
      }
    });
  }

  Future<void> _saveFriends() async {
    String friendsJson = jsonEncode(friends.map((f) => f.toJson()).toList());
    await prefs.setString('friends', friendsJson);
  }

  void _addFriend(String name) {
    setState(() {
      friends.add(Friend(name: name, birthdate: null, history: []));
      _saveFriends();
    });
  }

  void _removeFriend(Friend friend) {
    setState(() {
      friends.remove(friend);
      _saveFriends();
    });
  }

  void _addInteraction(Friend friend, int points, String interactionType,
      String date, String quality) {
    setState(() {
      friend.history.add({
        'interaction': interactionType,
        'date': date,
        'quality': quality,
        'points': points,
      });
      _saveFriends();
    });
    _cancelInteractionNotifications();
  }

  void _openAddFriendDialog() {
    String friendName = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Friend'),
          content: TextField(
            onChanged: (value) {
              friendName = value;
            },
            decoration: const InputDecoration(hintText: "Friend's Name"),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                _addFriend(friendName);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _openHistoryDialog(Friend friend) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('History of ${friend.name}'),
          // ignore: sized_box_for_whitespace
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: friend.history.length,
              itemBuilder: (BuildContext context, int index) {
                final interaction = friend.history[index];
                return ListTile(
                  title: Text(
                      "${interaction['interaction']} (${interaction['points']} pts)"),
                  subtitle: Text(
                      "${interaction['date'].toString().split("T")[0]} - ${interaction['quality']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _removeInteraction(friend, index);
                      Navigator.of(context).pop();
                      _openHistoryDialog(friend);
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _removeInteraction(Friend friend, int index) {
    setState(() {
      friend.history.removeAt(index);
      _saveFriends();
    });
  }

  void _openAddInteractionDialog(Friend friend) {
    String selectedInteraction = "S Talk/Chat";
    String selectedQuality = "Good";
    DateTime selectedDate = DateTime.now();
    int points = 5;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Interaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedInteraction,
                items: const [
                  DropdownMenuItem(
                      value: "S Talk/Chat",
                      child: Text("S Talk/Chat (<1 hrs)")),
                  DropdownMenuItem(
                      value: "L Talk/Chat",
                      child: Text("L Talk/Chat (>1 hrs)")),
                  DropdownMenuItem(
                      value: "S Meetup", child: Text("S 1:1 meetup (<3 hrs)")),
                  DropdownMenuItem(
                      value: "L Meetup", child: Text("L 1:1 meetup (>3 hrs)")),
                  DropdownMenuItem(
                      value: "S Group Meetup",
                      child: Text("S Group meetup (<4 hrs)")),
                  DropdownMenuItem(
                      value: "L Group Meetup",
                      child: Text("L Group meetup (>4 hrs)")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedInteraction = value!;
                    points = Friend.getPointsForInteraction(value);
                  });
                },
                decoration:
                    const InputDecoration(labelText: 'Interaction Type'),
              ),
              DropdownButtonFormField<String>(
                value: selectedQuality,
                items: const [
                  DropdownMenuItem(value: "Forced", child: Text("Forced")),
                  DropdownMenuItem(value: "Good", child: Text("Good")),
                  DropdownMenuItem(value: "Great", child: Text("Great")),
                ],
                onChanged: (value) {
                  selectedQuality = value!;
                },
                decoration: const InputDecoration(labelText: 'Quality'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Date: '),
                  TextButton(
                    child: Text("${selectedDate.toLocal()}".split(' ')[0]),
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null && pickedDate != selectedDate) {
                        setState(() {
                          selectedDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              DateTime.now().hour,
                              DateTime.now().minute);
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                _addInteraction(
                    friend,
                    Friend.calculateScore(points, selectedQuality),
                    selectedInteraction,
                    selectedDate.toIso8601String().split('.')[0],
                    selectedQuality);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _openEditFriendDialog(Friend friend) {
    TextEditingController nameController =
        TextEditingController(text: friend.name);
    DateTime selectedDate = friend.birthdate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Friend'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'New Name'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('Birthdate: '),
                      TextButton(
                        child: Text("${selectedDate.toLocal()}".split(' ')[0]),
                        onPressed: () async {
                          DateTime? pickedDate =
                              await _selectDate(context, selectedDate);
                          if (pickedDate != null &&
                              pickedDate != selectedDate) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Confirm'),
                  onPressed: () {
                    setState(() {
                      friend.name = nameController.text;
                      friend.birthdate = selectedDate;
                    });
                    Navigator.of(context).pop();
                    _saveFriends();
                    _loadFriends();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<DateTime?> _selectDate(
      BuildContext context, DateTime initialDate) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Friend> filteredFriends = friends
        .where((friend) =>
            friend.name.toLowerCase().contains(filter.toLowerCase()))
        .toList();
    List<Friend> displayedFriends =
        isExpanded ? filteredFriends : filteredFriends.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friendship Tracker'),
        centerTitle: true,
        backgroundColor: mainColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchField(),
          displayedFriends.isEmpty
              ? _buildNoFriendsWidget()
              : _buildFriendList(displayedFriends),
          if (filteredFriends.length > 3) _buildShowMoreButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddFriendDialog,
        backgroundColor: mainColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search Friends',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          labelStyle: TextStyle(
            color: commonGrey,
          ),
        ),
        onChanged: (value) {
          setState(() {
            filter = value;
          });
        },
        style: TextStyle(color: commonGrey),
      ),
    );
  }

  Widget _buildNoFriendsWidget() {
    return Center(
      child: Text(
        'No friends found',
        style: TextStyle(
          color: commonGrey,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFriendList(List<Friend> displayedFriends) {
    return Expanded(
      child: ListView.builder(
        itemCount: displayedFriends.length,
        itemBuilder: (context, index) {
          final friend = displayedFriends[index];
          return FriendListTile(
            friend: friend,
            onEdit: () => _openEditFriendDialog(friend),
            onViewHistory: () => _openHistoryDialog(friend),
            onAddInteraction: () => _openAddInteractionDialog(friend),
            onRemove: () => _removeFriend(friend),
          );
        },
      ),
    );
  }

  Widget _buildShowMoreButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: Text(isExpanded ? 'Show less' : 'Show more'),
    );
  }
}
