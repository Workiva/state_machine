import 'dart:async';

/// An implementation of `StreamSubscription` that provides a [didComplete]
/// future.
///
/// The [didComplete] future is used to provide an anchor point for removing
/// internal references to `StreamSubscriptions` if consumers manually cancel
/// the subscription. This class is not publicly exported.
///
/// There are three situations in which [didComplete] will be completed:
///   1. the managed subscription is canceled
///   2. the stream is closed
///   3. the stream sends an error and `cancelOnError` was set to `true`
class ManagedStreamSubscription<T> implements StreamSubscription<T> {
  final bool _cancelOnError;

  final StreamSubscription<T> _subscription;

  Completer<Null> _didComplete = Completer();

  ManagedStreamSubscription(Stream<T> stream, void onData(T arg),
      {Function? onError, void onDone()?, bool? cancelOnError})
      : _cancelOnError = cancelOnError ?? false,
        _subscription = stream.listen(onData, cancelOnError: cancelOnError) {
    _wrapOnDone(onDone);
    _wrapOnError(onError);
  }

  Future<Null> get didComplete => _didComplete.future;

  @override
  bool get isPaused => _subscription.isPaused;

  @override
  Future<E> asFuture<E>([E? futureValue]) {
    return _subscription.asFuture(futureValue).whenComplete(_complete);
  }

  @override
  Future<void> cancel() {
    var result = _subscription.cancel();

    // StreamSubscription.cancel() will return null if no cleanup was
    // necessary. This behavior is described in the docs as "for historical
    // reasons" so this may change in the future.
    // ignore: unnecessary_null_comparison
    if (result == null) {
      _complete();
      return Future(() {});
    }

    return result.then((_) {
      _complete();
    });
  }

  @override
  void onData(void handleData(T _)?) => _subscription.onData(handleData);

  @override
  void onDone(void handleDone()?) => _wrapOnDone(handleDone);

  @override
  void onError(Function? handleError) => _wrapOnError(handleError);

  @override
  void pause([Future<void>? resumeSignal]) => _subscription.pause(resumeSignal);

  @override
  void resume() => _subscription.resume();

  void _complete() {
    if (!_didComplete.isCompleted) {
      _didComplete.complete();
    }
  }

  void _wrapOnDone(void handleDone()?) {
    _subscription.onDone(() {
      if (handleDone != null) {
        handleDone();
      }

      _complete();
    });
  }

  void _wrapOnError(Function? handleError) {
    _subscription.onError((error, stackTrace) {
      if (handleError == null) {
        // By default unhandled stream errors are handled by their zone
        // error handler. In this case we *always* handle errors,
        // but the consumer may actually want the default behavior,
        // so in the case where the handler given to us by the consumer
        // is null (which is the default) we take the default action.
        Zone.current.handleUncaughtError(error, stackTrace);
      } else {
        // The onError handler can be either a unary callback that accepts only
        // the error, or a binary callback that accepts both the error and the
        // stack trace.
        // This is borrowed directly from the real StreamSubscription
        // implementation from dart:async (see stream_impl.dart).
        if (handleError is ZoneBinaryCallback<dynamic, Object, StackTrace>) {
          handleError(error, stackTrace);
        } else {
          handleError(error);
        }
      }

      if (_cancelOnError) {
        _complete();
      }
    });
  }
}
