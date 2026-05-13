class ContentModel {
  final String id;
  final String slug;
  final String title;
  final String body;

  // Flexible CMS-style sections
  final Map<String, dynamic> sections;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ContentModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.body,
    required this.sections,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── JSON factory ────────────────────────────────────────────────────────────
  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: (json['_id'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),

      // Safe dynamic object parsing
      sections: json['sections'] is Map<String, dynamic>
          ? json['sections'] as Map<String, dynamic>
          : {},

      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,

      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  // ── Convert to JSON ─────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'slug': slug,
      'title': title,
      'body': body,
      'sections': sections,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ── Copy helper ─────────────────────────────────────────────────────────────
  ContentModel copyWith({
    String? id,
    String? slug,
    String? title,
    String? body,
    Map<String, dynamic>? sections,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContentModel(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      body: body ?? this.body,
      sections: sections ?? this.sections,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}