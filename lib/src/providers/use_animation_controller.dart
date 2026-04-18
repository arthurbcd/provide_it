import '../framework.dart';
import 'use_single_ticker_provider.dart';

extension ContextUseAnimationController on BuildContext {
  /// The default duration for [useAnimationController.duration].
  static Duration duration = Duration(milliseconds: 600);

  /// Creates an [AnimationController] for the current [BuildContext].
  ///
  /// The controller automatically disposes with `this` context.
  ///
  /// When not provided, the following parameters will:
  /// - [duration] defaults to [ContextUseAnimationController.duration].
  /// - [reverseDuration] defaults to [duration].
  /// - [vsync] defaults to [useSingleTickerProvider].
  ///
  AnimationController useAnimationController({
    Duration? duration,
    Duration? reverseDuration,
    String? debugLabel,
    double initialValue = 0.0,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    TickerProvider? vsync,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    Object? key,
  }) {
    vsync ??= useSingleTickerProvider(key: key);
    duration ??= ContextUseAnimationController.duration;
    reverseDuration ??= duration;

    return bind(
      _UseAnimationController(
        duration: duration,
        reverseDuration: reverseDuration,
        debugLabel: debugLabel,
        initialValue: initialValue,
        lowerBound: lowerBound,
        upperBound: upperBound,
        vsync: vsync,
        animationBehavior: animationBehavior,
        key: key,
      ),
    );
  }
}

class _UseAnimationController extends HookProvider<AnimationController> {
  const _UseAnimationController({
    this.duration,
    this.reverseDuration,
    this.debugLabel,
    required this.initialValue,
    required this.lowerBound,
    required this.upperBound,
    required this.vsync,
    required this.animationBehavior,
    super.key,
  });

  final Duration? duration;
  final Duration? reverseDuration;
  final String? debugLabel;
  final double initialValue;
  final double lowerBound;
  final double upperBound;
  final TickerProvider vsync;
  final AnimationBehavior animationBehavior;

  @override
  _UseAnimationControllerState createState() => _UseAnimationControllerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('duration', duration));
    properties.add(DiagnosticsProperty('reverseDuration', reverseDuration));
  }
}

class _UseAnimationControllerState
    extends HookState<AnimationController, _UseAnimationController> {
  @override
  String get debugLabel => 'useAnimationController';

  late final controller = AnimationController(
    value: provider.initialValue,
    duration: provider.duration,
    debugLabel: provider.debugLabel,
    reverseDuration: provider.reverseDuration,
    lowerBound: provider.lowerBound,
    upperBound: provider.upperBound,
    animationBehavior: provider.animationBehavior,
    vsync: provider.vsync,
  );

  @override
  void didUpdateProvider(_UseAnimationController oldProvider) {
    super.didUpdateProvider(oldProvider);
    if (provider.duration != oldProvider.duration) {
      controller.duration = provider.duration;
    }
    if (provider.reverseDuration != oldProvider.reverseDuration) {
      controller.reverseDuration = provider.reverseDuration;
    }
    if (provider.vsync != oldProvider.vsync) {
      controller.resync(provider.vsync);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  AnimationController build(BuildContext context) {
    return controller;
  }
}
