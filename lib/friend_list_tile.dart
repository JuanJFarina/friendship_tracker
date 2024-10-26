import 'package:flutter/material.dart';
import 'friend.dart';
import 'utils.dart';
import 'color_constants.dart';

class FriendListTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback onEdit;
  final VoidCallback onViewHistory;
  final VoidCallback onAddInteraction;
  final VoidCallback onRemove;

  const FriendListTile({
    required this.friend,
    required this.onEdit,
    required this.onViewHistory,
    required this.onAddInteraction,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    Color nameColor = !friend.needsInteraction() ? mainColor : commonGrey;
    Color scoreColor = _getScoreColor(friend);
    Color birthdayColor = _getBirthdayColor(friend);
    String birthdate = _getBirthdayText(friend);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        title: GestureDetector(
          onTap: onEdit,
          child: Text(
            friend.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: nameColor,
            ),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interaction score: ${friend.score}\n${friend.status}',
              style: TextStyle(fontSize: 16, color: scoreColor),
            ),
            const SizedBox(height: 4),
            Text(
              birthdate,
              style: TextStyle(color: birthdayColor, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.history),
              color: blueAccent,
              onPressed: onViewHistory,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              color: greenAccent,
              onPressed: onAddInteraction,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: redAlert,
              onPressed: onRemove,
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getScoreColor(Friend friend) {
    if (friend.score > 10) {
      return commonGrey;
    } else if (friend.score <= 10 && friend.score > 3) {
      return yellowAlert;
    } else {
      return redAlert;
    }
  }
  
  Color _getBirthdayColor(Friend friend) {
    final days = Utils.getDaysToNextBirthdate(friend.birthdate);
    if (days != -1 && days < 30) {
      return mainColor;
    }
    return commonGrey;
  }

  String _getBirthdayText(Friend friend) {
    final birthdateString = "${friend.birthdate?.toLocal()}".split(' ')[0];
    if (birthdateString != "null"){
      return "Birthdate: $birthdateString\nDays left: ${Utils.getDaysToNextBirthdate(friend.birthdate)}";
    }
    return "Add your friend's birthdate to track their birthday!";
  }
}
