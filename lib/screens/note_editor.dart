import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_service.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import '../widgets/retro_components.dart';

class NoteEditor extends StatefulWidget {
  final Note? note;

  const NoteEditor({super.key, this.note});

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  final _titleController = TextEditingController();
  Color _selectedColor = Colors.blueAccent;
  bool _isPinned = false;
  bool _isLocked = false;
  List<String> _imagePaths = [];
  List<ChecklistItem> _checklists = [];
  Note? _currentNote;
  
  Timer? _autoSaveTimer;
  final _uuid = const Uuid();
  bool _isFocusMode = false;

  late quill.QuillController _quillController;
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _audioPath;
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  final List<Color> _colors = [
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.greenAccent,
    Colors.redAccent,
    Colors.pinkAccent,
  ];

  void _onChanged() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _autoSave);
  }

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    if (_currentNote != null) {
      _titleController.text = _currentNote!.title;
      _selectedColor = _currentNote!.color;
      _isPinned = _currentNote!.isPinned;
      _isLocked = _currentNote!.isLocked;
      _imagePaths = List.from(_currentNote!.imagePaths);
      _checklists = List.from(_currentNote!.checklists);
    }
    
    _titleController.addListener(_onChanged);
    _initQuill();
    _initAudio();
  }

  void _initQuill() {
    if (_currentNote != null && _currentNote!.content.isNotEmpty) {
      try {
        final doc = quill.Document.fromJson(jsonDecode(_currentNote!.content));
        _quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        final doc = quill.Document()..insert(0, _currentNote!.content);
        _quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      _quillController = quill.QuillController.basic();
    }
    _quillController.addListener(_onChanged);
  }

  void _initAudio() {
    if (_currentNote != null) {
      _audioPath = _currentNote!.audioPath;
    }
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _audioDuration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _audioPosition = position;
      });
    });
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = p.join(directory.path, 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a');
        
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _audioPath = path;
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
      _onChanged();
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _toggleAudio() async {
    if (_audioPath == null) return;
    
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(_audioPath!));
    }
  }

  void _autoSave() {
    if (!mounted) return;
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    _updateNoteInProvider(noteProvider);
  }

  void _updateNoteInProvider(NoteProvider noteProvider) {
    if (_titleController.text.isEmpty && 
        _quillController.document.isEmpty() && 
        _imagePaths.isEmpty && 
        _checklists.isEmpty &&
        _audioPath == null) {
      return;
    }


    final content = jsonEncode(_quillController.document.toDelta().toJson());
    
    final updatedNote = Note(
      id: _currentNote?.id ?? _uuid.v4(),
      title: _titleController.text.isEmpty ? 'Untitled' : _titleController.text,
      content: content,
      dateTime: DateTime.now(),
      color: _selectedColor,
      isPinned: _isPinned,
      isLocked: _isLocked,
      imagePaths: List.from(_imagePaths),
      checklists: _checklists.map((item) => ChecklistItem(
        id: item.id,
        title: item.title,
        isDone: item.isDone,
      )).toList(),
      versions: _currentNote?.versions ?? [],
      audioPath: _audioPath,
    );
    
    if (_currentNote == null) {
      noteProvider.addNote(updatedNote);
      _currentNote = updatedNote;
    } else {
      noteProvider.updateNote(updatedNote);
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _quillController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _saveNote(NoteProvider noteProvider, {bool isExiting = false}) {
    final hasContent = _titleController.text.trim().isNotEmpty || 
                      _quillController.document.toPlainText().trim().isNotEmpty || 
                      _imagePaths.isNotEmpty || 
                      _checklists.isNotEmpty || 
                      _audioPath != null;
                      
    if (!hasContent) {
      if (!isExiting) Navigator.of(context).pop();
      return;
    }

    _updateNoteInProvider(noteProvider);

    if (!isExiting) Navigator.of(context).pop();
  }

  void _undo() => _quillController.undo();
  void _redo() => _quillController.redo();

  Future<void> _exportAsPDF() async {
    final pdfDoc = pw.Document();
    final content = _quillController.document.toPlainText();
    
    pdfDoc.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(_titleController.text, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text(content),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/${_titleController.text.replaceAll(' ', '_')}.pdf");
    await file.writeAsBytes(await pdfDoc.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Exported Note: ${_titleController.text}');
  }

  void _exportAsTXT() {
    final content = _quillController.document.toPlainText();
    Share.share("${_titleController.text}\n\n$content");
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePaths.add(pickedFile.path);
      });
      _onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context);
    final isRetro = noteProvider.isRetroTheme;

    if (isRetro) {
      return _buildRetroEditor(context);
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _saveNote(noteProvider, isExiting: true);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1E),
        appBar: _isFocusMode ? null : AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => _saveNote(noteProvider),
          ),
          actions: [
            IconButton(
              icon: Icon(_isFocusMode ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white70),
              onPressed: () => setState(() => _isFocusMode = !_isFocusMode),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.share, color: Colors.white70),
              onSelected: (val) {
                if (val == 'pdf') _exportAsPDF();
                if (val == 'txt') _exportAsTXT();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
                const PopupMenuItem(value: 'txt', child: Text('Export as TXT')),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.undo, color: Colors.white70),
              onPressed: _quillController.hasUndo ? _undo : null,
            ),
            IconButton(
              icon: const Icon(Icons.redo, color: Colors.white70),
              onPressed: _quillController.hasRedo ? _redo : null,
            ),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.blueAccent, size: 28),
              onPressed: () => _saveNote(noteProvider),
            ),
            const SizedBox(width: 8),
          ],
        ),
        bottomNavigationBar: _isFocusMode ? null : BottomAppBar(
          color: const Color(0xFF16162A),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(_isLocked ? Icons.lock : Icons.lock_open, 
                     color: _isLocked ? Colors.orangeAccent : Colors.white70),
                onPressed: () async {
                  bool authenticated = await AuthService.authenticate();
                  if (authenticated) {
                    setState(() => _isLocked = !_isLocked);
                    _onChanged();
                  }
                },
              ),
              IconButton(
                icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined, 
                     color: _isPinned ? Colors.blueAccent : Colors.white70),
                onPressed: () {
                  setState(() => _isPinned = !_isPinned);
                  _onChanged();
                },
              ),
              IconButton(
                icon: const Icon(Icons.image_outlined, color: Colors.white70),
                onPressed: _pickImage,
              ),
              IconButton(
                icon: Icon(_isRecording ? Icons.stop : Icons.mic, 
                     color: _isRecording ? Colors.redAccent : Colors.white70),
                onPressed: _isRecording ? _stopRecording : _startRecording,
              ),
              if (_currentNote != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                    Provider.of<NoteProvider>(context, listen: false).deleteNote(_currentNote!.id);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
        body: GestureDetector(
          onScaleUpdate: (details) {
            if (details.pointerCount == 3 && _isFocusMode) {
              setState(() => _isFocusMode = false);
            }
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.all(_isFocusMode ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isFocusMode) ...[
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 28),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colors.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedColor = _colors[index]);
                            _onChanged();
                          },
                          child: Container(
                            width: 40,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: _colors[index],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedColor == _colors[index] ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_imagePaths.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagePaths.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(_imagePaths[index]), height: 200, width: 200, fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_checklists.isNotEmpty)
                    Column(
                      children: _checklists.asMap().entries.map((entry) {
                        int idx = entry.key;
                        ChecklistItem item = entry.value;
                        return Row(
                          children: [
                            Checkbox(
                              value: item.isDone,
                              onChanged: (val) {
                                setState(() => item.isDone = val!);
                                _onChanged();
                              },
                              activeColor: Colors.blueAccent,
                            ),
                            Expanded(
                              child: TextField(
                                controller: TextEditingController(text: item.title)..selection = TextSelection.collapsed(offset: item.title.length),
                                style: TextStyle(
                                  color: Colors.white,
                                  decoration: item.isDone ? TextDecoration.lineThrough : null,
                                ),
                                onChanged: (val) {
                                  item.title = val;
                                  _onChanged();
                                },
                                decoration: const InputDecoration(border: InputBorder.none),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                              onPressed: () {
                                setState(() => _checklists.removeAt(idx));
                                _onChanged();
                              },
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _checklists.add(ChecklistItem(id: _uuid.v4(), title: '')));
                      _onChanged();
                    },
                    icon: const Icon(Icons.add_task, color: Colors.blueAccent),
                    label: const Text('Add Checklist Item', style: TextStyle(color: Colors.blueAccent)),
                  ),
                  const SizedBox(height: 16),
                  if (_audioPath != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E3A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.blueAccent),
                            onPressed: _toggleAudio,
                          ),
                          Expanded(
                            child: Slider(
                              value: _audioPosition.inMilliseconds.toDouble(),
                              max: _audioDuration.inMilliseconds.toDouble() > 0 
                                  ? _audioDuration.inMilliseconds.toDouble() 
                                  : 1.0,
                              onChanged: (value) => _audioPlayer.seek(Duration(milliseconds: value.toInt())),
                              activeColor: Colors.blueAccent,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () {
                              setState(() => _audioPath = null);
                              _onChanged();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
                quill.QuillSimpleToolbar(
                  controller: _quillController,
                  config: const quill.QuillSimpleToolbarConfig(
                    showSearchButton: false,
                    showFontFamily: false,
                    showFontSize: false,
                  ),
                ),
                const SizedBox(height: 16),
                quill.QuillEditor(
                  controller: _quillController,
                  scrollController: ScrollController(),
                  focusNode: FocusNode(),
                  config: const quill.QuillEditorConfig(
                    scrollable: false,
                    autoFocus: false,
                    expands: false,
                    padding: EdgeInsets.zero,
                    placeholder: 'Start typing...',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRetroEditor(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    final color = const Color(0xFF00FF41);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _saveNote(noteProvider),
                    child: Text('< EXIT.EXE', style: GoogleFonts.vt323(color: color, fontSize: 18)),
                  ),
                  Text('STATUS: WRITING...', style: GoogleFonts.vt323(color: color, fontSize: 14)),
                ],
              ),
              const Divider(color: Color(0xFF00FF41)),
              TextField(
                controller: _titleController,
                style: GoogleFonts.vt323(color: color, fontSize: 28, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'TITLE.LOG',
                  hintStyle: GoogleFonts.vt323(color: color.withOpacity(0.3), fontSize: 28),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: quill.QuillEditor(
                  controller: _quillController,
                  scrollController: ScrollController(),
                  focusNode: FocusNode(),
                  config: quill.QuillEditorConfig(
                    scrollable: true,
                    autoFocus: true,
                    expands: false,
                    padding: EdgeInsets.zero,
                    placeholder: 'type your messy thoughts here...',
                  ),
                ),
              ),
              const Divider(color: Color(0xFF00FF41)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PixelButton(text: 'SAVE', onTap: () => _saveNote(noteProvider), color: color),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.image, color: color),
                        onPressed: _pickImage,
                      ),
                      IconButton(
                        icon: Icon(Icons.mic, color: color),
                        onPressed: _startRecording,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
