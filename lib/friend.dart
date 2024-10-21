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
