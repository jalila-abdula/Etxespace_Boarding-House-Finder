import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class MultiSnap extends StatelessWidget {
  final List<Stream<Snap>> streams;
  final Widget Function(BuildContext context, List<Snap> data) builder;
  const MultiSnap({super.key, required this.streams, required this.builder});

  Widget _build(BuildContext context, int i, List<Snap> acc) {
    if (i == streams.length) return builder(context, acc);
    return StreamBuilder<Snap>(
      stream: streams[i],
      builder: (ctx, s) {
        if (s.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load data.\n${s.error}',
                  textAlign: TextAlign.center),
            ),
          );
        }
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        return _build(ctx, i + 1, [...acc, s.data!]);
      },
    );
  }

  @override
  Widget build(BuildContext context) => _build(context, 0, <Snap>[]);
}