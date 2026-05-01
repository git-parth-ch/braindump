import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/note_provider.dart';
import '../widgets/note_card.dart';
import 'note_editor.dart';
import '../providers/auth_service.dart';
import '../models/note.dart';
import 'trash_screen.dart';
import '../widgets/retro_components.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context);
    final isRetro = noteProvider.isRetroTheme;

    if (isRetro) {
      return _buildRetroHomeScreen(context, noteProvider);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      drawer: _buildDrawer(context, noteProvider),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withAlpha(25),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildNoteGrid(noteProvider),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NoteEditor()));
        },
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildRetroHomeScreen(BuildContext context, NoteProvider noteProvider) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: _buildDrawer(context, noteProvider),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: Text(
                        '[ MENU ]',
                        style: GoogleFonts.vt323(color: const Color(0xFF00FF41), fontSize: 20),
                      ),
                    ),
                  ),
                  Text(
                    'RAM: 640KB OK',
                    style: GoogleFonts.vt323(color: const Color(0xFF00FF41), fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'C:\\BRAIN_DUMP>',
                style: GoogleFonts.vt323(
                  color: const Color(0xFF00FF41),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'READY TO DUMP THOUGHTS?',
                style: GoogleFonts.vt323(color: const Color(0xFF00FF41), fontSize: 18),
              ),
              const SizedBox(height: 20),
              RetroInput(
                controller: _searchController,
                hint: 'type your messy thoughts here...',
                onChanged: (val) => noteProvider.setSearchQuery(val),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: PixelButton(
                  text: 'ENTER',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NoteEditor()));
                  },
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '--- SAVED_FILES.LOG ---',
                style: GoogleFonts.vt323(color: const Color(0xFF00FF41), fontSize: 18),
              ),
              const SizedBox(height: 12),
              _buildNoteGrid(noteProvider),
              const SizedBox(height: 16),
              Text(
                'STATUS: PROCESSING CHAOS...',
                style: GoogleFonts.vt323(color: const Color(0xFF00FF41).withOpacity(0.5), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const SizedBox(width: 8),
          if (!_isSearching)
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Notes',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'printf your thoughts here...',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            )
          else
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            Provider.of<NoteProvider>(context, listen: false).setSearchQuery('');
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  Provider.of<NoteProvider>(context, listen: false).setSearchQuery(value);
                  setState(() {});
                },
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    Provider.of<NoteProvider>(context, listen: false).setSearchQuery('');
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteGrid(NoteProvider noteProvider) {
    if (noteProvider.notes.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('No notes found.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: noteProvider.notes.length,
        itemBuilder: (context, index) {
          final Note note = noteProvider.notes[index];
          return NoteCard(
            note: note,
            onTap: () async {
              if (note.isLocked) {
                bool authenticated = await AuthService.authenticate();
                if (!authenticated) return;
              }
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => NoteEditor(note: note)),
              );
            },
          ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.1);
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, NoteProvider noteProvider) {
    final isRetro = noteProvider.isRetroTheme;
    final color = isRetro ? const Color(0xFF00FF41) : Colors.white;
    final bgColor = isRetro ? Colors.black : const Color(0xFF16162A);

    return Drawer(
      backgroundColor: bgColor,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: isRetro ? Colors.black : const Color(0xFF1E1E3A)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isRetro ? color : Colors.blueAccent).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.psychology, color: isRetro ? color : Colors.blueAccent, size: 40),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Brain Dump',
                    style: isRetro
                        ? GoogleFonts.vt323(color: color, fontSize: 24)
                        : const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.notes, color: color.withOpacity(0.7)),
            title: Text('All Notes', style: TextStyle(color: color)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: color.withOpacity(0.7)),
            title: Text('Trash', style: TextStyle(color: color)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashScreen()));
            },
          ),
          const Divider(color: Colors.white24),
          SwitchListTile(
            title: Text('RETRO TERMINAL', style: isRetro ? GoogleFonts.vt323(color: color, fontSize: 18) : null),
            value: noteProvider.isRetroTheme,
            activeThumbColor: const Color(0xFF00FF41),
            onChanged: (val) => noteProvider.toggleRetroTheme(),
          ),
          if (isRetro)
            SwitchListTile(
              title: Text('CRT EFFECT', style: GoogleFonts.vt323(color: color, fontSize: 18)),
              value: noteProvider.isCRTEnabled,
              activeThumbColor: const Color(0xFF00FF41),
              onChanged: (val) => noteProvider.toggleCRT(val),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              isRetro ? 'BUILD: 0x29A-DUMP' : 'v2.0.0 Premium',
              style: TextStyle(color: color.withOpacity(0.24), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

}
