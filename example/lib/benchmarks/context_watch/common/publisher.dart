import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'observable_listener_types.dart';

sealed class Publisher {
  Publisher._({
    required this.observableCount,
    required this.initialDelay,
    required this.interval,
  });

  factory Publisher({
    required ObservableType observableType,
    required int observableCount,
    required Duration initialDelay,
    required Duration interval,
  }) {
    switch (observableType) {
      case ObservableType.future:
      case ObservableType.synchronousFuture:
        throw UnimplementedError();
      case ObservableType.stream:
        return StreamPublisher(
          observableCount: observableCount,
          initialDelay: initialDelay,
          interval: interval,
        );
      case ObservableType.valueListenable:
        return ValueNotifierPublisher(
          observableCount: observableCount,
          initialDelay: initialDelay,
          interval: interval,
        );
      default:
        throw UnimplementedError();
    }
  }

  final int observableCount;
  final Duration initialDelay;
  final Duration interval;

  bool _isDisposed = false;

  @protected
  void publish(int index);

  @nonVirtual
  Future<void> publishWhileMounted(BuildContext context) async {
    var index = 0;
    if (initialDelay > Duration.zero) {
      await Future.delayed(initialDelay);
    }
    while (context.mounted && !_isDisposed) {
      publish(index);
      index++;
      await Future.delayed(interval);
    }
  }

  @nonVirtual
  void dispose() {
    _isDisposed = true;
    _dispose();
  }

  @protected
  void _dispose();
}

final class StreamPublisher extends Publisher {
  StreamPublisher({
    required super.observableCount,
    required super.initialDelay,
    required super.interval,
  }) : super._() {
    final streams = <Stream<int>>[];
    for (var i = 0; i < observableCount; i++) {
      final streamController = StreamController<int>.broadcast();
      _streamControllers.add(streamController);
      streams.add(streamController.stream);
    }
    this.streams = UnmodifiableListView(streams);
  }

  final _streamControllers = <StreamController<int>>[];
  late final List<Stream<int>> streams;

  @override
  void publish(int index) {
    for (final controller in _streamControllers) {
      controller.add(index);
    }
  }

  @override
  void _dispose() {
    for (final controller in _streamControllers) {
      controller.close();
    }
  }
}

final class ValueNotifierPublisher extends Publisher {
  ValueNotifierPublisher({
    required super.observableCount,
    required super.initialDelay,
    required super.interval,
  }) : super._() {
    final valueListenables = <ValueListenable<int>>[];
    for (var i = 0; i < observableCount; i++) {
      final valueNotifier = ValueNotifier<int>(0);
      _valueNotifiers.add(valueNotifier);
      valueListenables.add(valueNotifier);
    }
    this.valueListenables = UnmodifiableListView(valueListenables);
  }

  final _valueNotifiers = <ValueNotifier<int>>[];
  late final List<ValueListenable<int>> valueListenables;

  @override
  void publish(int index) {
    for (final notifier in _valueNotifiers) {
      notifier.value = index;
    }
  }

  @override
  void _dispose() {
    for (final notifier in _valueNotifiers) {
      notifier.dispose();
    }
  }
}
