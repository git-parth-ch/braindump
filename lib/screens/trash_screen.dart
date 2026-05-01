import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/note_provider.dart';
import 'package:intl/intl.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context);
    final isRetro = noteProvider.isRetroTheme;
    final color = isRetro ? const Color(0xFF00FF41) : Colors.white;

    final trashNotes = noteProvider.trashNotes.where((note) {
      return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             note.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: isRetro ? Colors.black : const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: Text(
          isRetro ? 'ARCHIVE.LOG' : 'Trash',
          style: isRetro
              ? GoogleFonts.vt323(color: color, fontSize: 24)
              : const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(isRetro ? Icons.arrow_back : Icons.arrow_back_ios, color: color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          if (isRetro) const Divider(color: Color(0xFF00FF41)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: isRetro ? GoogleFonts.vt323(color: color, fontSize: 18) : const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: isRetro ? 'search_archive...' : 'Search trash...',
                hintStyle: TextStyle(color: color.withOpacity(0.5)),
                prefixIcon: Icon(isRetro ? Icons.chevron_right : Icons.search, color: color.withOpacity(0.5)),
                filled: true,
                fillColor: isRetro ? Colors.black : const Color(0xFF1E1E3A),
                enabledBorder: isRetro
                    ? OutlineInputBorder(borderSide: BorderSide(color: color, width: 1))
                    : OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: isRetro
                    ? OutlineInputBorder(borderSide: BorderSide(color: color, width: 2))
                    : OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          if (trashNotes.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  isRetro ? 'NO_THOUGHTS_DETECTED. SUSPICIOUS.' : 'Trash is empty',
                  style: isRetro ? GoogleFonts.vt323(color: color, fontSize: 20) : const TextStyle(color: Colors.white54),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: trashNotes.length,
                itemBuilder: (context, index) {
                  final note = trashNotes[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isRetro ? Colors.black : const Color(0xFF1E1E3A),
                      border: isRetro ? Border.all(color: color, width: 1) : null,
                      borderRadius: isRetro ? null : BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        isRetro ? 'RECOVERABLE: ${note.title.toUpperCase()}.BAK' : note.title,
                        style: isRetro
                            ? GoogleFonts.vt323(color: color, fontSize: 18)
                            : const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Deleted: ${DateFormat(isRetro ? 'yyyy.MM.dd' : 'MMM d, h:mm a').format(note.deletedAt ?? DateTime.now())}',
                        style: TextStyle(color: color.withOpacity(0.5), fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.restore, color: isRetro ? color : Colors.greenAccent),
                            onPressed: () => noteProvider.restoreFromTrash(note.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                            onPressed: () {
                              _showDeleteDialog(context, noteProvider, note.id, isRetro, color);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, NoteProvider noteProvider, String noteId, bool isRetro, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isRetro ? Colors.black : const Color(0xFF1E1E3A),
        shape: isRetro ? Border.all(color: color, width: 2) as ShapeBorder : null,
        title: Text(
          isRetro ? 'PURGE_SYSTEM?' : 'Permanently Delete?',
          style: isRetro ? GoogleFonts.vt323(color: color) : const TextStyle(color: Colors.white),
        ),
        content: Text(
          isRetro ? 'THIS_ACTION_IS_IRREVERSIBLE. CONTINUE?' : 'This action cannot be undone.',
          style: isRetro ? GoogleFonts.vt323(color: color.withOpacity(0.7)) : const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isRetro ? '[ CANCEL ]' : 'Cancel', style: GoogleFonts.vt323(color: color)),
          ),
          TextButton(
            onPressed: () {
              noteProvider.deleteNotePermanently(noteId);
              Navigator.pop(ctx);
            },
            child: Text(isRetro ? '[ PURGE ]' : 'Delete', style: GoogleFonts.vt323(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
