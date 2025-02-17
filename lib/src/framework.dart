import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:provide_it/src/injector/injector.dart';
import 'package:provide_it/src/injector/param.dart';
import 'package:provide_it/src/watchers/listenable.dart';

import '../provide_it.dart';
import 'refs/async.dart';
import 'refs/ref.dart';
import 'utils/tree_map.dart';

part 'framework/provide_it_binding.dart';
part 'framework/provide_it_caching.dart';
part 'framework/provide_it_element.dart';
part 'framework/ref_state.dart';
part 'framework/ref_state_cycling.dart';
part 'framework/watcher.dart';
