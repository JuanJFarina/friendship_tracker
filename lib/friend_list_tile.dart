import 'package:flutter/material.dart';
import 'friend.dart';
import 'utils.dart';

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
    Color nameColor = _getNameColor(friend);
    Color scoreColor = _getScoreColor(friend);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
          onTap: onEdit,
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
              onPressed: onViewHistory,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              color: Colors.green,
              onPressed: onAddInteraction,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.redAccent,
              onPressed: onRemove,
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getNameColor(Friend friend) {
    return !friend.needsInteraction() ? Colors.purple[700]! : Colors.grey[700]!;
  }

  Color _getScoreColor(Friend friend) {
    if (friend.score > 10) {
      return Colors.grey[700]!;
    } else if (friend.score <= 10 && friend.score > 3) {
      return Colors.yellow[900]!;
    } else {
      return Colors.red[800]!;
    }
  }
}
