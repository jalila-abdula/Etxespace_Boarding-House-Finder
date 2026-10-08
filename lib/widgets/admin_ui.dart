import 'package:flutter/material.dart';

class Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const Pill(this.text, this.bg, this.fg, {super.key});
  const Pill.green(this.text, {super.key})
      : bg = const Color(0xFFE8F8EE),
        fg = const Color(0xFF00A844);
  const Pill.red(this.text, {super.key})
      : bg = const Color(0xFFFDECEC),
        fg = const Color(0xFFD32F2F);
  const Pill.orange(this.text, {super.key})
      : bg = const Color(0xFFFFF3E0),
        fg = const Color(0xFFE65100);
  const Pill.grey(this.text, {super.key})
      : bg = const Color(0xFFF1F3F4),
        fg = const Color(0xFF5F6368);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(fontSize: 11, color: fg)),
      );
}

BoxDecoration cardDeco([double radius = 18]) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4)),
      ],
    );

/// Title row used at the top of admin tabs. Shows a back arrow only when the
/// screen was opened on top of another one.
class AdminHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const AdminHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      child: Row(
        children: [
          if (Navigator.of(context).canPop())
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            )
          else
            const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

Future<bool> confirmDialog(BuildContext context, String title, String body,
    {String yes = 'Yes', bool danger = false}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back')),
        TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(yes,
                style: TextStyle(color: danger ? Colors.red : null))),
      ],
    ),
  );
  return ok == true;
}

void toast(BuildContext context, String m) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));