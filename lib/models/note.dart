import 'package:flutter/material.dart';

class ChecklistItem {
  String id;
  String title;
  bool isDone;

  ChecklistItem({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'isDone': isDone};
  factory ChecklistItem.fromMap(Map<dynamic, dynamic> map) => ChecklistItem(
        id: map['id'],
        title: map['title'],
        isDone: map['isDone'],
      );
}

class NoteVersion {
  final String content;
  final DateTime dateTime;

  NoteVersion({required this.content, required this.dateTime});

  Map<String, dynamic> toMap() => {'content': content, 'dateTime': dateTime.toIso8601String()};
  factory NoteVersion.fromMap(Map<dynamic, dynamic> map) => NoteVersion(
        content: map['content'],
        dateTime: DateTime.parse(map['dateTime']),
      );
}

class Note {
  final String id;
  String title;
  String content;
  DateTime dateTime;
  Color color;
  bool isPinned;
  bool isLocked;
  List<ChecklistItem> checklists;
  List<String> imagePaths;
  List<NoteVersion> versions;
  String? audioPath;
  bool isDeleted;
  DateTime? deletedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.dateTime,
    required this.color,
    this.isPinned = false,
    this.isLocked = false,
    this.checklists = const [],
    this.imagePaths = const [],
    this.versions = const [],
    this.audioPath,
    this.isDeleted = false,
    this.deletedAt,
  });
}
