class HomepageContentModel {
  final String id;
  final String slug;
  final String title;
  final String body;

  final List<TopCondition> topConditions;
  final List<MedicationNeed> medicationNeeds;
  final List<String> keyDrivers;

  HomepageContentModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.body,
    required this.topConditions,
    required this.medicationNeeds,
    required this.keyDrivers,
  });

  factory HomepageContentModel.fromJson(Map<String, dynamic> json) {
    final sections = Map<String, dynamic>.from(json['sections'] ?? {});

    return HomepageContentModel(
      id: json['_id']?.toString() ?? '',
      slug: json['slug'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',

      topConditions: (sections['top_conditions'] ?? [])
          .map<TopCondition>((e) => TopCondition.fromJson(e))
          .toList(),

      medicationNeeds: (sections['medication_needs'] ?? [])
          .map<MedicationNeed>((e) => MedicationNeed.fromJson(e))
          .toList(),

      keyDrivers: List<String>.from(sections['key_drivers'] ?? []),
    );
  }
}

class TopCondition {
  final int percent;
  final int change;
  final String title;
  final String color;

  TopCondition({
    required this.percent,
    required this.change,
    required this.title,
    required this.color,
  });

  factory TopCondition.fromJson(Map<String, dynamic> json) {
    return TopCondition(
      percent: int.tryParse(json['percent'].toString()) ?? 0,
      change: int.tryParse(json['change'].toString()) ?? 0,
      title: json['title'] ?? '',
      color: json['color'] ?? 'blue',
    );
  }
}

class MedicationNeed {
  final String name;
  final String amount;
  final String risk;

  MedicationNeed({
    required this.name,
    required this.amount,
    required this.risk,
  });

  factory MedicationNeed.fromJson(Map<String, dynamic> json) {
    return MedicationNeed(
      name: json['name'] ?? '',
      amount: json['amount'] ?? '',
      risk: json['risk'] ?? '',
    );
  }
}