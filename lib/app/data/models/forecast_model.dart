import 'package:cloud_firestore/cloud_firestore.dart';

class ForecastModel {
  final String? id; // Null if it hasn't been saved to Firestore yet
  final String forecasterId;
  final String forecasterName; // NEW
  final String approvedBy;     // NEW (Will be empty if not approved yet)
  final String updatedBy;      // NEW (Name of the last person to edit it)
  
  final String department;
  final String status; // "draft", "pending_approval", "approved"
  final String issueTime;
  final String validity;
  final String date; // e.g., "2026-10-24"
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  final Map<String, dynamic> metadata;
  final List<Map<String, dynamic>> tableData;
  final Map<String, dynamic> mapData;

  ForecastModel({
    this.id,
    required this.forecasterId,
    required this.forecasterName,
    this.approvedBy = '', // Defaults to empty string
    required this.updatedBy,
    required this.department,
    required this.status,
    required this.issueTime,
    required this.validity,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.metadata,
    required this.tableData,
    required this.mapData,
  });

  factory ForecastModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ForecastModel(
      id: doc.id,
      forecasterId: data['forecasterId'] ?? '',
      forecasterName: data['forecasterName'] ?? 'Unknown Forecaster',
      approvedBy: data['approvedBy'] ?? '',
      updatedBy: data['updatedBy'] ?? '',
      department: data['department'] ?? '',
      status: data['status'] ?? 'draft',
      issueTime: data['issueTime'] ?? '',
      validity: data['validity'] ?? '',
      date: data['date'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] ?? {},
      tableData: List<Map<String, dynamic>>.from(data['tableData'] ?? []),
      mapData: data['mapData'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'forecasterId': forecasterId,
      'forecasterName': forecasterName,
      'approvedBy': approvedBy,
      'updatedBy': updatedBy,
      'department': department,
      'status': status,
      'issueTime': issueTime,
      'validity': validity,
      'date': date,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
      'tableData': tableData,
      'mapData': mapData,
    };
  }
}