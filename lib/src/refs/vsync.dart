import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:provide_it/src/refs/provide.dart';

import '../framework/framework.dart';

extension ContextVsync on BuildContext {
  /// Creates a single [TickerProvider] for the current [BuildContext].
  ///
  /// Must be used exactly once, preferably within [Create].
  TickerProvider get vsync {
    assert(
      ProvideItRootElement.instance.debugDoingInit,
      'context.vsync must be used within Ref.create/initState method.',
    );

    return _TickerProvider(this);
  }
}

class _TickerProvider implements TickerProvider {
  _TickerProvider(this.context);
  final BuildContext context;

  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick, debugLabel: 'created by $context');
  }
}
