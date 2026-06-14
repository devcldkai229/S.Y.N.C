import 'package:flutter_bloc/flutter_bloc.dart';

/// Guards async handlers from emitting after [Cubit.close].
mixin SafeEmitMixin<S> on Cubit<S> {
  void safeEmit(S state) {
    if (!isClosed) emit(state);
  }
}
