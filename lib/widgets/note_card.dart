import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/note.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../providers/note_provider.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteCard({super.key, required this.note, required this.onTap});

  String _getPlainText(String jsonContent) {
    if (jsonContent.isEmpty) return '';
    try {
      final List<dynamic> delta = jsonDecode(jsonContent);
      return delta.map((op) {
        if (op['insert'] is String) {
          return op['insert'];
        }
        return '';
      }).join().trim();
    } catch (e) {
      return jsonContent;
    }
  }

  void _showQuickOptions(BuildContext context, NoteProvider noteProvider) {
    final isRetro = noteProvider.isRetroTheme;
    final color = isRetro ? const Color(0xFF00FF41) : Colors.white;
    final bgColor = isRetro ? Colors.black : const Color(0xFF16162A);

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRetro) const Divider(color: Color(0xFF00FF41), thickness: 2),
              ListTile(
                leading: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: color),
                title: Text(note.isPinned ? 'Unpin Note' : 'Pin Note', 
                    style: isRetro ? GoogleFonts.vt323(color: color, fontSize: 18) : TextStyle(color: color)),
                onTap: () {
                  note.isPinned = !note.isPinned;
                  noteProvider.updateNote(note);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text('Delete Note', 
                    style: isRetro ? GoogleFonts.vt323(color: Colors.redAccent, fontSize: 18) : const TextStyle(color: Colors.redAccent)),
                onTap: () {
                  noteProvider.deleteNote(note.id);
                  Navigator.pop(context);
                },
              ),
              if (isRetro) const Divider(color: Color(0xFF00FF41), thickness: 2),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context);
    final isRetro = noteProvider.isRetroTheme;
    final retroColor = const Color(0xFF00FF41);

    if (isRetro) {
      return _buildRetroCard(retroColor, context, noteProvider);
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showQuickOptions(context, noteProvider),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: note.color.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: note.color.withAlpha(50), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (note.isPinned)
                  const Icon(Icons.push_pin, size: 16, color: Colors.blueAccent),
              ],
            ),
            const SizedBox(height: 8),
            if (note.isLocked)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, color: Colors.white24, size: 32),
                      SizedBox(height: 4),
                      Text(
                        'Locked Note',
                        style: TextStyle(color: Colors.white24, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              if (note.imagePaths.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(note.imagePaths.first),
                      height: 60,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  _getPlainText(note.content),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withAlpha(180),
                  ),
                  maxLines: note.imagePaths.isNotEmpty ? 2 : 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd').format(note.dateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withAlpha(100),
                  ),
                ),
                Icon(
                  Icons.edit_note,
                  size: 16,
                  color: note.color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetroCard(Color color, BuildContext context, NoteProvider noteProvider) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showQuickOptions(context, noteProvider),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: color, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FILE: ${note.title.toUpperCase().replaceAll(' ', '_')}.LOG',
              style: GoogleFonts.vt323(color: color, fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(color: Color(0xFF00FF41), thickness: 0.5),
            Expanded(
              child: Text(
                note.isLocked ? '--- [ LOCKED ] ---' : _getPlainText(note.content),
                style: GoogleFonts.vt323(color: color.withOpacity(0.7), fontSize: 14),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'DATE: ${DateFormat('yyyy.MM.dd').format(note.dateTime)}',
              style: GoogleFonts.vt323(color: color.withOpacity(0.4), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
