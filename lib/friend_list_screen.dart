import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart';
import 'dart:convert';
import 'friend.dart';
import 'utils.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
        AndroidInitializationSettings('@mipmap/ic_launcher');

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

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _scheduleNextNotification();
  }

  void _getHoursFromLastInteraction() {
    int hours = 240;
    for (var friend in friends) {
      if (friend.history.isNotEmpty) {
        DateTime lastInteraction = DateTime.parse(friend.history.last['date']);
        Duration difference = DateTime.now().difference(lastInteraction);
        if (hours > difference.inHours) {
          hours = difference.inHours;
        }
      }
    }
    hoursFromLastInteraction = hours;
  }

  Future<void> _scheduleNextNotification() async {
    TZDateTime? date;
    String? message;
    bool scheduleNotification = false;
    if (Utils.isLessThanFourHoursAway(10) && hoursFromLastInteraction >= 24) {
      date = Utils.nextInstanceOfNHour(10);
      message = "Remember to check in with your friends today ! :)";
      scheduleNotification = true;
    } else if (Utils.isLessThanFourHoursAway(18) &&
        hoursFromLastInteraction >= 24 &&
        (DateTime.now().weekday == 5 || DateTime.now().weekday == 6)) {
      date = Utils.nextInstanceOfNHour(18);
      message = "Why not go out with your friends tonight ?";
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

  Future<void> _cancelAllNotifications() async {
    await widget.flutterLocalNotificationsPlugin.cancelAll();
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
    _getHoursFromLastInteraction();
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
    _cancelAllNotifications();
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
    List<Friend> displayedFriends =
        isExpanded ? friends : friends.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friendship Tracker'),
        centerTitle: true,
        backgroundColor: Colors.purple[400],
        elevation: 0,
      ),
      body: displayedFriends.isEmpty
          ? Center(
              child: Text(
                'No friends found',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Column(children: [
              Expanded(
                child: ListView.builder(
                  itemCount: displayedFriends.length,
                  itemBuilder: (context, index) {
                    final friend = displayedFriends[index];
                    Color nameColor = !friend.needsInteraction()
                        ? Colors.purple[700]!
                        : Colors.grey[700]!;
                    Color scoreColor = friend.score > 10
                        ? Colors.grey[700]!
                        : friend.score <= 10 && friend.score > 3
                            ? Colors.yellow[900]!
                            : Colors.red[800]!;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(15),
                        title: GestureDetector(
                          child: Text(
                            friend.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: nameColor,
                            ),
                          ),
                          onTap: () {
                            _openEditFriendDialog(friend);
                          },
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Score: ${friend.score}, Status: ${friend.status}',
                              style: TextStyle(fontSize: 16, color: scoreColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Birthdate: ${"${friend.birthdate?.toLocal()}".split(' ')[0]}, Days left: ${Utils.getDaysToNextBirthdate(friend.birthdate)}",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.history),
                              color: Colors.blueAccent,
                              onPressed: () {
                                _openHistoryDialog(friend);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              color: Colors.green,
                              onPressed: () {
                                _openAddInteractionDialog(friend);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.redAccent,
                              onPressed: () {
                                _removeFriend(friend);
                              },
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
              if (friends.length > 3)
                TextButton(
                  onPressed: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                  child: Text(isExpanded ? 'Show less' : 'Show more'),
                ),
            ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddFriendDialog,
        backgroundColor: Colors.purpleAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
