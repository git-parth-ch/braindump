import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/note.dart';

class NoteProvider with ChangeNotifier {
  List<Note> _notes = [];
  String _searchQuery = '';
  final Box _box = Hive.box('notes_box');
  bool _isRetroTheme = false;
  bool _isCRTEnabled = true;

  bool get isRetroTheme => _isRetroTheme;
  bool get isCRTEnabled => _isCRTEnabled;

  void toggleRetroTheme() {
    _isRetroTheme = !_isRetroTheme;
    _box.put('isRetroTheme', _isRetroTheme);
    notifyListeners();
  }

  void toggleCRT(bool value) {
    _isCRTEnabled = value;
    _box.put('isCRTEnabled', _isCRTEnabled);
    notifyListeners();
  }

  List<Note> get notes {
    List<Note> activeNotes = _notes.where((note) => !note.isDeleted).toList();
    
    List<Note> filteredNotes = activeNotes.where((note) {
      final titleMatch = note.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final contentMatch = note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      return titleMatch || contentMatch;
    }).toList();

    // Sort: Pinned notes first, then by date (newest first)
    filteredNotes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.dateTime.compareTo(a.dateTime);
    });

    return filteredNotes;
  }

  List<Note> get trashNotes {
    return _notes.where((note) => note.isDeleted).toList()
      ..sort((a, b) => b.deletedAt?.compareTo(a.deletedAt ?? DateTime.now()) ?? 0);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadNotes() async {
    _isRetroTheme = _box.get('isRetroTheme', defaultValue: false);
    _isCRTEnabled = _box.get('isCRTEnabled', defaultValue: true);
    final data = _box.get('notes', defaultValue: []);
    _notes = (data as List).map((item) {
      final map = Map<dynamic, dynamic>.from(item);
      return Note(
        id: map['id'],
        title: map['title'],
        content: map['content'],
        dateTime: DateTime.parse(map['dateTime']),
        color: Color(map['color'] as int),
        isPinned: map['isPinned'] ?? false,
        isLocked: map['isLocked'] ?? false,
        imagePaths: List<String>.from(map['imagePaths'] ?? []),
        checklists: (map['checklists'] as List? ?? [])
            .map((c) => ChecklistItem.fromMap(c))
            .toList(),
        versions: (map['versions'] as List? ?? [])
            .map((v) => NoteVersion.fromMap(v))
            .toList(),
        audioPath: map['audioPath'],
        isDeleted: map['isDeleted'] ?? false,
        deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt']) : null,
      );
    }).toList();
    
    // Auto-purge old trash (older than 30 days)
    final now = DateTime.now();
    _notes.removeWhere((note) => 
      note.isDeleted && 
      note.deletedAt != null && 
      now.difference(note.deletedAt!).inDays > 30
    );
    
    notifyListeners();
  }

  Future<void> _saveToHive() async {
    final data = _notes.map((note) => {
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'dateTime': note.dateTime.toIso8601String(),
      'color': note.color.toARGB32(), // Simplified color storage
      'isPinned': note.isPinned,
      'isLocked': note.isLocked,
      'imagePaths': note.imagePaths,
      'checklists': note.checklists.map((c) => c.toMap()).toList(),
      'versions': note.versions.map((v) => v.toMap()).toList(),
      'audioPath': note.audioPath,
      'isDeleted': note.isDeleted,
      'deletedAt': note.deletedAt?.toIso8601String(),
    }).toList();
    await _box.put('notes', data);
  }

  void addNote(Note note) {
    _notes.insert(0, note);
    _saveToHive();
    notifyListeners();
  }

  void updateNote(Note updatedNote) {
    final index = _notes.indexWhere((n) => n.id == updatedNote.id);
    if (index >= 0) {
      // Add to version history if content changed
      if (_notes[index].content != updatedNote.content) {
        final history = List<NoteVersion>.from(updatedNote.versions);
        history.add(NoteVersion(
          content: _notes[index].content,
          dateTime: _notes[index].dateTime,
        ));
        updatedNote.versions = history;
      }
      
      _notes[index] = updatedNote;
      _saveToHive();
      notifyListeners();
    }
  }

  void togglePin(String id) {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _notes[index].isPinned = !_notes[index].isPinned;
      _saveToHive();
      notifyListeners();
    }
  }

  void moveToTrash(String id) {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _notes[index].isDeleted = true;
      _notes[index].deletedAt = DateTime.now();
      _saveToHive();
      notifyListeners();
    }
  }

  void restoreFromTrash(String id) {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _notes[index].isDeleted = false;
      _notes[index].deletedAt = null;
      _saveToHive();
      notifyListeners();
    }
  }

  void deleteNotePermanently(String id) {
    _notes.removeWhere((n) => n.id == id);
    _saveToHive();
    notifyListeners();
  }

  void deleteNote(String id) {
    moveToTrash(id);
  }
}
