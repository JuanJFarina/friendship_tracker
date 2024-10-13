import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'friend.dart';
import 'utils.dart';

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
      DateTime? nextBirthdayA = Utils.getNextBirthday(a.birthdate, today);
      // Get the next birthday for friend b
      DateTime? nextBirthdayB = Utils.getNextBirthday(b.birthdate, today);

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
                    Friend.calculateScore(points, selectedQuality),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friendship Tracker'),
        centerTitle: true,
        backgroundColor: Colors.purple[400], // Add a fun and bright color
        elevation: 0,
      ),
      body: friends.isEmpty
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
          : ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
                          color: Colors.purple[700], // Playful color
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
                          style: const TextStyle(fontSize: 16),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddFriendDialog,
        backgroundColor: Colors.purpleAccent, // Matches the app's theme
        child: const Icon(Icons.add),
      ),
    );
  }
}
