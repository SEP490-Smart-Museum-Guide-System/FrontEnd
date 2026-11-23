class NotificationItem {
  final int id;
  final String? recipientId;
  final int? museumId;
  final String type;
  final String title;
  final String body;
  final String? referenceType;
  final String? referenceId;
  final String? actionUrl;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    this.recipientId,
    this.museumId,
    required this.type,
    required this.title,
    required this.body,
    this.referenceType,
    this.referenceId,
    this.actionUrl,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] as num).toInt(),
      recipientId: json['recipientId']?.toString(),
      museumId: (json['museumId'] as num?)?.toInt(),
      type: json['type']?.toString() ?? 'SYSTEM',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      referenceType: json['referenceType']?.toString(),
      referenceId: json['referenceId']?.toString(),
      actionUrl: json['actionUrl']?.toString(),
      isRead: json['isRead'] == true,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipientId': recipientId,
        'museumId': museumId,
        'type': type,
        'title': title,
        'body': body,
        'referenceType': referenceType,
        'referenceId': referenceId,
        'actionUrl': actionUrl,
        'isRead': isRead,
        'readAt': readAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  NotificationItem copyWith({
    int? id,
    String? recipientId,
    int? museumId,
    String? type,
    String? title,
    String? body,
    String? referenceType,
    String? referenceId,
    String? actionUrl,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      museumId: museumId ?? this.museumId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      actionUrl: actionUrl ?? this.actionUrl,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class NotificationPageData {
  final List<NotificationItem> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const NotificationPageData({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory NotificationPageData.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? [];
    return NotificationPageData(
      items: rawItems
          .map((i) => NotificationItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
