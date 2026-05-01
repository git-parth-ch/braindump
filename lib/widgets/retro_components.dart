import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PixelButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color? color;

  const PixelButton({super.key, required this.text, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: color ?? const Color(0xFF00FF41), width: 2),
          boxShadow: [
            BoxShadow(
              color: (color ?? const Color(0xFF00FF41)).withOpacity(0.3),
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Text(
          '[ $text ]',
          style: GoogleFonts.vt323(
            color: color ?? const Color(0xFF00FF41),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class PixelCard extends StatelessWidget {
  final Widget child;
  final String? label;

  const PixelCard({super.key, required this.child, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: const Color(0xFF00FF41), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: GoogleFonts.vt323(
                color: const Color(0xFF00FF41),
                fontSize: 14,
                backgroundColor: const Color(0xFF00FF41).withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(child: child),
        ],
      ),
    );
  }
}

class RetroInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Function(String)? onChanged;

  const RetroInput({super.key, required this.controller, required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: const Color(0xFF00FF41), width: 1),
      ),
      child: Row(
        children: [
          Text(
            '> ',
            style: GoogleFonts.vt323(color: const Color(0xFF00FF41), fontSize: 24),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.vt323(color: const Color(0xFF00FF41), fontSize: 20),
              cursorColor: const Color(0xFF00FF41),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.vt323(
                  color: const Color(0xFF00FF41).withOpacity(0.4),
                  fontSize: 20,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const BlinkingCursor(),
        ],
      ),
    );
  }
}

class BlinkingCursor extends StatefulWidget {
  const BlinkingCursor({super.key});

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 10,
        height: 20,
        color: const Color(0xFF00FF41),
      ),
    );
  }
}
