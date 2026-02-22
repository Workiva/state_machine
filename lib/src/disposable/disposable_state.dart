/// Lifecycle states of a Disposable instance.
enum DisposableState {
  initialized,
  awaitingDisposal,
  disposing,
  disposed,
}
