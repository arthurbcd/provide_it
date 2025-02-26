import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provide_it/provide_it.dart';

import '../../context_watch/common/publisher.dart';
import 'observable_listener_types.dart';

class Observer extends StatelessWidget {
  const Observer({
    super.key,
    required this.publisher,
    required this.listenerType,
    required this.visualize,
  });

  final Publisher publisher;
  final ListenerType listenerType;
  final bool visualize;

  @override
  Widget build(BuildContext context) {
    return switch (publisher) {
      StreamPublisher(:final streams) => _buildStreamObserver(streams),
      ValueNotifierPublisher(:final valueListenables) =>
        _buildValueListenableObserver(valueListenables),
    };
  }

  Widget _buildStreamObserver(List<Stream<int>> streams) {
    return switch (listenerType) {
      ListenerType.contextWatch =>
        _ContextWatchStream(streams: streams, visualize: visualize),
      ListenerType.streamBuilder =>
        _StreamBuilder(streams: streams, visualize: visualize),
      _ => Center(
          child: Text(
            'ListenerType $listenerType is not supported for a Stream',
          ),
        ),
    };
  }

  Widget _buildValueListenableObserver(
    List<ValueListenable<int>> valueListenables,
  ) {
    return switch (listenerType) {
      ListenerType.contextWatch => _ContextWatchValueListenable(
          valueListenables: valueListenables,
          visualize: visualize,
        ),
      ListenerType.listenableBuilder => _ListenableBuilder(
          listenables: valueListenables,
          visualize: visualize,
        ),
      ListenerType.valueListenableBuilder => _ValueListenableBuilder(
          valueListenables: valueListenables,
          visualize: visualize,
        ),
      _ => throw UnsupportedError(
          'ListenerType $listenerType is not supported for a ValueListenable',
        ),
    };
  }
}

class _ContextWatchValueListenable extends StatelessWidget {
  const _ContextWatchValueListenable({
    required this.valueListenables,
    required this.visualize,
  });

  final List<ValueListenable<int>> valueListenables;
  final bool visualize;

  @override
  Widget build(BuildContext context) {
    final color = context.provideValue(
      valueListenables.firstOrNull ?? const _ConstValueListenable(0),
      key: 'colorIndex',
    );

    final scale = context.provideValue(
      valueListenables.secondOrNull ?? const _ConstValueListenable(0),
      key: 'scaleIndex',
    );
    for (final (i, valueListenable) in valueListenables.skip(2).indexed) {
      context.provideValue(valueListenable, key: i);
    }
    return _buildFromValues(
      colorIndex: color.value,
      scaleIndex: scale.value,
      visualize: visualize,
    );
  }
}

class _ContextWatchStream extends StatelessWidget {
  const _ContextWatchStream({
    required this.streams,
    required this.visualize,
  });

  final List<Stream<int>> streams;
  final bool visualize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'ListenerType contextWatch is not supported for a Stream',
      ),
    );
    // context.stream(
    //   () => streams.firstOrNull ?? Stream.value(0),
    //   key: 'colorIndex',
    // );

    // AsyncSnapshot<int>? colorIndexSnapshot =
    //     streams.firstOrNull?.watch(context);
    // AsyncSnapshot<int>? scaleIndexSnapshot =
    //     streams.secondOrNull?.watch(context);
    // for (final stream in streams.skip(2)) {
    //   stream.watch(context);
    // }
    // return _buildAsyncSnapshot(
    //   colorIndexSnapshot: colorIndexSnapshot,
    //   scaleIndexSnapshot: scaleIndexSnapshot,
    //   visualize: visualize,
    // );
  }
}

class _ListenableBuilder extends StatelessWidget {
  const _ListenableBuilder({
    required this.listenables,
    required this.visualize,
  });

  final List<Listenable> listenables;
  final bool visualize;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenables.firstOrNull ?? const _ConstValueListenable(-1),
      builder: (context, child) {
        return ListenableBuilder(
          listenable:
              listenables.secondOrNull ?? const _ConstValueListenable(-1),
          builder: (context, child) {
            Widget child = _buildFromValues(
              colorIndex: null,
              scaleIndex: null,
              visualize: visualize,
            );
            for (final listenable in listenables.skip(2)) {
              final currentChild = child;
              child = ListenableBuilder(
                listenable: listenable,
                builder: (context, child) => currentChild,
              );
            }
            return child;
          },
        );
      },
    );
  }
}

class _ValueListenableBuilder extends StatelessWidget {
  const _ValueListenableBuilder({
    required this.valueListenables,
    required this.visualize,
  });

  final List<ValueListenable<int>> valueListenables;
  final bool visualize;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable:
          valueListenables.firstOrNull ?? const _ConstValueListenable(-1),
      builder: (context, colorIndex, child) {
        return ValueListenableBuilder(
          valueListenable:
              valueListenables.secondOrNull ?? const _ConstValueListenable(-1),
          builder: (context, scaleIndex, child) {
            Widget child = _buildFromValues(
              colorIndex: colorIndex,
              scaleIndex: scaleIndex,
              visualize: visualize,
            );
            for (final valueListenable in valueListenables.skip(2)) {
              final currentChild = child;
              child = ValueListenableBuilder(
                valueListenable: valueListenable,
                builder: (context, snapshot, child) => currentChild,
              );
            }
            return child;
          },
        );
      },
    );
  }
}

class _StreamBuilder extends StatelessWidget {
  const _StreamBuilder({
    required this.streams,
    required this.visualize,
  });

  final List<Stream<int>> streams;
  final bool visualize;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: streams.firstOrNull,
      builder: (context, snapshot) {
        final colorIndexSnapshot = snapshot;
        return StreamBuilder(
          stream: streams.secondOrNull,
          builder: (context, snapshot) {
            final scaleIndexSnapshot = snapshot;
            Widget child = _buildAsyncSnapshot(
              colorIndexSnapshot: colorIndexSnapshot,
              scaleIndexSnapshot: scaleIndexSnapshot,
              visualize: visualize,
            );
            for (final stream in streams.skip(2)) {
              final currentChild = child;
              child = StreamBuilder(
                stream: stream,
                builder: (context, snapshot) => currentChild,
              );
            }
            return child;
          },
        );
      },
    );
  }
}

Widget _buildAsyncSnapshot({
  required AsyncSnapshot<int>? colorIndexSnapshot,
  required AsyncSnapshot<int>? scaleIndexSnapshot,
  required bool visualize,
}) {
  if (!visualize) {
    return const SizedBox.shrink();
  }

  const loadingColor = Color(0xFFFFFACA);

  final child = switch (colorIndexSnapshot) {
    AsyncSnapshot(hasData: true, requireData: final colorIndex) =>
      ColoredBox(color: _colors[colorIndex % _colors.length]),
    AsyncSnapshot(hasError: false) => const ColoredBox(color: loadingColor),
    AsyncSnapshot(hasError: true) => const ColoredBox(color: Colors.red),
    null => ColoredBox(color: Colors.grey.shade300),
  };

  final scaledChild = switch (scaleIndexSnapshot) {
    AsyncSnapshot(hasData: true, requireData: final scaleIndex) =>
      Transform.scale(
        scale: _scales[scaleIndex % _scales.length],
        child: child,
      ),
    AsyncSnapshot(hasError: false) => child,
    AsyncSnapshot(hasError: true) => const ColoredBox(color: Colors.red),
    null => child,
  };

  return scaledChild;
}

Widget _buildFromValues({
  required int? colorIndex,
  required int? scaleIndex,
  required bool visualize,
}) {
  if (!visualize) {
    return const SizedBox.shrink();
  }

  final child = switch (colorIndex) {
    -1 || null => ColoredBox(color: Colors.grey.shade300),
    int() => ColoredBox(color: _colors[colorIndex % _colors.length]),
  };

  final scaledChild = switch (scaleIndex) {
    -1 || null => child,
    int() => Transform.scale(
        scale: _scales[scaleIndex % _scales.length],
        child: child,
      ),
  };

  return scaledChild;
}

final _colors = _generateGradient(Colors.white, Colors.grey.shade400, 32);
List<Color> _generateGradient(Color startColor, Color endColor, int steps) {
  List<Color> gradientColors = [];
  int halfSteps = steps ~/ 2; // integer division to get half the steps
  for (int i = 0; i < halfSteps; i++) {
    double t = i / (halfSteps - 1);
    gradientColors.add(Color.lerp(startColor, endColor, t)!);
  }
  for (int i = 0; i < halfSteps; i++) {
    double t = i / (halfSteps - 1);
    gradientColors.add(Color.lerp(endColor, startColor, t)!);
  }
  return gradientColors;
}

final _scales = _generateScales(0.5, 0.9, 32);
List<double> _generateScales(double startScale, double endScale, int steps) {
  List<double> scales = [];
  int halfSteps = steps ~/ 2; // integer division to get half the steps
  for (int i = 0; i < halfSteps; i++) {
    double t = i / (halfSteps - 1);
    scales.add(startScale + (endScale - startScale) * t);
  }
  for (int i = 0; i < halfSteps; i++) {
    double t = i / (halfSteps - 1);
    scales.add(endScale + (startScale - endScale) * t);
  }
  return scales;
}

extension _ListExtensions<T> on List<T> {
  T? get firstOrNull => length > 0 ? this[0] : null;
  T? get secondOrNull => length > 1 ? this[1] : null;
}

class _ConstValueListenable<T> implements ValueListenable<T> {
  const _ConstValueListenable(this.value);

  @override
  final T value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
