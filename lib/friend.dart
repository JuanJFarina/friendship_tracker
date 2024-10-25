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
      return 'No interactions yet';
    }
    Map<String, dynamic> lastInteraction = history.last;
    DateTime lastInteractionDate = DateTime.parse(lastInteraction['date']);
    int daysSinceInteraction =
        DateTime.now().difference(lastInteractionDate).inDays;
    int interactionPoints = lastInteraction['points'];
    if (interactionPoints > daysSinceInteraction) {
      if (score >= 60) {
        return "Great, you're pretty much best friends !";
      } else if (score >= 30) {
        return 'You have a good relationship, try doing something new !';
      } else if (score >= 15) {
        return "Your friendship is growing, why not go out together ?";
      } else {
        return "You're just starting so keep reaching out !";
      }
    }
    if (score >= 20) {
      return "Now's a good time to go out with your friend";
    } else if (score >= 10) {
      return 'Time to make a call and do something together !';
    } else if (score >= 5) {
      return "Hey, go see how is your friend doing !";
    } else {
      return "You'll have to start over again";
    }
  }

  static int getPointsForInteraction(String interactionType) {
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

  static int calculateScore(int points, String quality) {
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

  bool needsInteraction() {
    if (history.isEmpty) {
      return true;
    }
    Map<String, dynamic> lastInteraction = history.last;
    DateTime lastInteractionDate = DateTime.parse(lastInteraction['date']);
    return lastInteraction['points'] <=
        DateTime.now().difference(lastInteractionDate).inDays;
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
      birthdate:
          json['birthdate'] != null ? DateTime.parse(json['birthdate']) : null,
      history: List<Map<String, dynamic>>.from(json['history']),
    );
  }
}
