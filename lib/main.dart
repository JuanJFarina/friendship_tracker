import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

class Friend {
  String name;
  DateTime? birthdate;
  List<Map<String, dynamic>> history;

  Friend({required this.name, required this.birthdate, required this.history});

  int get score {
    if (history.isEmpty) return 0;

    int totalScore = 0;
    history.sort((a, b) => a['date'].compareTo(b['date']));

    for (var i = 0; i < history.length; i++) {
      int daysSinceInteraction = 0;
      DateTime interactionDate = DateTime.parse(history[i]['date']);
      if (i < (history.length - 1)) {
        DateTime nextInteractionDate = DateTime.parse(history[i + 1]['date']);
        daysSinceInteraction =
            nextInteractionDate.difference(interactionDate).inDays;
      } else {
        daysSinceInteraction =
            DateTime.now().difference(interactionDate).inDays;
      }
      int interactionPoints = history[i]['points'];

      totalScore -= daysSinceInteraction;
      totalScore += interactionPoints;

      if (totalScore < 0) {
        totalScore = 0;
      }
    }

    return totalScore;
  }

  String get status {
    if (history.isEmpty) {
      return 'No interactions yet'; // Default message when history is empty
    }
    Map<String, dynamic> lastInteraction = history.last;
    DateTime lastInteractionDate = DateTime.parse(lastInteraction['date']);
    int daysSinceInteraction =
        DateTime.now().difference(lastInteractionDate).inDays;
    int interactionPoints = lastInteraction['points'];
    if (interactionPoints > daysSinceInteraction) {
      if (score >= 60) {
        return "OK, you're great friends !";
      } else if (score >= 30) {
        return 'OK, you have a good relationship, try doing something new !';
      } else if (score >= 15) {
        return "OK, starting to grow, why not go out together ?";
      } else {
        return 'OK, just starting so keep reaching out';
      }
    }
    if (score >= 60) {
      return "OK, you're great friends but keep in touch";
    } else if (score >= 30) {
      return 'BAD, reach out more often';
    } else if (score >= 15) {
      return 'BAD, get in touch as soon as possible';
    } else {
      return 'BAD, starting over again';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'birthdate': birthdate?.toIso8601String(),
      'history': history,
    };
  }

  static Friend fromJson(Map<String, dynamic> json) {
    return Friend(
      name: json['name'],
      birthdate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate']) // Parse DateTime from String
          : null,
      history: List<Map<String, dynamic>>.from(json['history']),
    );
  }
}

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FriendListScreenState createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  List<Friend> friends = [];
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _loadFriends();
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
      // Get the next birthday for friend a
      DateTime? nextBirthdayA = _getNextBirthday(a.birthdate, today);
      // Get the next birthday for friend b
      DateTime? nextBirthdayB = _getNextBirthday(b.birthdate, today);

      // Sort by the number of days until their next birthday
      if (nextBirthdayA != null && nextBirthdayB != null) {
        return nextBirthdayA.compareTo(nextBirthdayB);
      } else if (nextBirthdayA != null) {
        return -1; // friend a's birthday is closer
      } else if (nextBirthdayB != null) {
        return 1; // friend b's birthday is closer
      } else {
        return 0; // Both friends have no birthdate
      }
    });
  }

  DateTime? _getNextBirthday(DateTime? birthdate, DateTime today) {
    if (birthdate == null) return null;

    // Create the birthday for the current year
    DateTime nextBirthday =
        DateTime(today.year, birthdate.month, birthdate.day);

    // If the birthday has already passed this year, use next year's birthday
    if (nextBirthday.month <= today.month && nextBirthday.day < today.day) {
      return DateTime(today.year + 1, birthdate.month, birthdate.day);
    }
    return nextBirthday;
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
                      "${interaction['date']} - ${interaction['quality']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _removeInteraction(friend, index);
                      Navigator.of(context)
                          .pop(); // Close the dialog and refresh
                      _openHistoryDialog(
                          friend); // Re-open the dialog with updated history
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
      friend.history
          .removeAt(index); // Remove the interaction at the given index
      _saveFriends(); // Save the updated list
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
                    points = _getPointsForInteraction(value);
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
                    child: Text("${selectedDate.toLocal()}"
                        .split(' ')[0]), // Show selected date
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate, // Default to current date
                        firstDate: DateTime(2000), // Start from year 2000
                        lastDate: DateTime.now(), // Don't allow future dates
                      );
                      if (pickedDate != null && pickedDate != selectedDate) {
                        setState(() {
                          selectedDate = pickedDate; // Update selected date
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
                    _calculateScore(points, selectedQuality),
                    selectedInteraction,
                    selectedDate.toIso8601String().split('T')[0],
                    selectedQuality);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  int _getPointsForInteraction(String interactionType) {
    switch (interactionType) {
      case "S Talk/Chat":
        return 5;
      case "L Talk/Chat":
        return 10;
      case "S Meetup":
        return 20;
      case "L Meetup":
        return 40;
      case "S Group Meetup":
        return 10;
      case "L Group Meetup":
        return 20;
      default:
        return 0;
    }
  }

  int _calculateScore(int points, String quality) {
    switch (quality) {
      case "Forced":
        return (points * 0.5).round();
      case "Good":
        return points;
      case "Great":
        return (points * 1.5).round();
      default:
        return points;
    }
  }

  void _openEditFriendDialog(Friend friend) {
    TextEditingController nameController =
        TextEditingController(text: friend.name);
    DateTime selectedDate = friend.birthdate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Use StatefulBuilder to manage state inside dialog
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
                      friend.birthdate =
                          selectedDate; // Save the updated birthdate
                    });
                    Navigator.of(context).pop();
                    _saveFriends(); // Persist changes
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
      firstDate: DateTime(1920), // Set the earliest date available
      lastDate: DateTime.now(), // Disallow future dates
    );
  }

  int _getDaysToNextBirthdate(DateTime? birthdate) {
    DateTime? next = _getNextBirthday(birthdate, DateTime.now());
    if (next == null) {
      return -1;
    }
    DateTime today = DateTime.now();
    if (next.month == today.month && next.day == today.day) {
      return 0;
    }
    int days = next.difference(DateTime.now()).inDays;
    return days + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friendship Tracker'),
      ),
      body: ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          return ListTile(
            title: GestureDetector(
              child: Text(friend.name),
              onTap: () {
                _openEditFriendDialog(friend);
              },
            ),
            subtitle: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Aligns text to the left
              children: [
                Text('Score: ${friend.score}, Status: ${friend.status}'),
                Text(
                  "Birthdate: ${"${friend.birthdate?.toLocal()}".split(' ')[0]}, Days left: ${_getDaysToNextBirthdate(friend.birthdate)}",
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    _openHistoryDialog(friend);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _openAddInteractionDialog(friend);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _removeFriend(friend);
                  },
                ),
              ],
            ),
            isThreeLine: true,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddFriendDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
