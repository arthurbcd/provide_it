import 'package:flutter/scheduler.dart';

import '../framework.dart';

extension ContextUseSingleTickerProvider on BuildContext {
  /// Creates a single [TickerProvider] for the current [BuildContext].
  /// See: [SingleTickerProviderStateMixin].
  TickerProvider useSingleTickerProvider({Object? key}) {
    return bind(
      key == null
          ? const _SingleTickerProviderHook()
          : _SingleTickerProviderHook(key: key),
    );
  }
}

class _SingleTickerProviderHook extends HookProvider<TickerProvider> {
  const _SingleTickerProviderHook({super.key});

  @override
  _SingleTickerProviderHookState createState() =>
      _SingleTickerProviderHookState();
}

/// Copied from [SingleTickerProviderStateMixin].
class _SingleTickerProviderHookState
    extends HookState<TickerProvider, _SingleTickerProviderHook>
    implements TickerProvider {
  @override
  String get debugLabel => 'useSingleTickerProvider';

  Ticker? _ticker;

  @override
  Ticker createTicker(TickerCallback onTick) {
    assert(() {
      if (_ticker == null) {
        return true;
      }
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
          'useSingleTickerProvider was used to create multiple tickers.',
        ),
        ErrorDescription(
          'A useSingleTickerProvider hook can only be used as a TickerProvider once.',
        ),
        ErrorHint(
          'If you need multiple AnimationControllers, consider calling '
          'useSingleTickerProvider multiple times, one for each controller.',
        ),
      ]);
    }());
    _ticker = Ticker(
      onTick,
      debugLabel: kDebugMode ? 'created by ${describeIdentity(this)}' : null,
    );
    _updateTickerModeNotifier();
    _updateTicker(); // Sets _ticker.mute correctly.
    return _ticker!;
  }

  @override
  void dispose() {
    assert(() {
      if (_ticker == null || !_ticker!.isActive) {
        return true;
      }
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('$this was disposed with an active Ticker.'),
        ErrorDescription(
          '$runtimeType created a Ticker via its useSingleTickerProvider, but at the time '
          'dispose() was called on the mixin, that Ticker was still active. The Ticker must '
          'be disposed before calling super.dispose().',
        ),
        ErrorHint(
          'Tickers used by AnimationControllers '
          'should be disposed by calling dispose() on the AnimationController itself. '
          'Otherwise, the ticker will leak.',
        ),
        _ticker!.describeForError('The offending ticker was'),
      ]);
    }());
    _tickerModeNotifier?.removeListener(_updateTicker);
    _tickerModeNotifier = null;
    super.dispose();
  }

  ValueListenable<TickerModeData>? _tickerModeNotifier;

  @override
  void activate() {
    super.activate();
    // We may have a new TickerMode ancestor.
    _updateTickerModeNotifier();
    _updateTicker();
  }

  void _updateTicker() {
    final TickerModeData values = _tickerModeNotifier!.value;
    if (_ticker != null) {
      _ticker!.muted = !values.enabled;
      _ticker!.forceFrames = values.forceFrames;
    }
  }

  void _updateTickerModeNotifier() {
    final ValueListenable<TickerModeData> newNotifier =
        TickerMode.getValuesNotifier(context);
    if (newNotifier == _tickerModeNotifier) {
      return;
    }
    _tickerModeNotifier?.removeListener(_updateTicker);
    newNotifier.addListener(_updateTicker);
    _tickerModeNotifier = newNotifier;
  }

  @override
  TickerProvider build(BuildContext context) {
    return this;
  }
}
