class InjectorInjectableInstanceScopeContainer {
  final int parentInjectorId;
  final Future<Object> serviceFuture;
  final String? name;

  // dynamic tempInstance; // this is a work around until we can fix the bug
  InjectorInjectableInstanceScopeContainer(
    this.parentInjectorId,
    this.serviceFuture, {
    this.name,
  }) {
    debugFutureType();
  }

  // Debugging method to check the type of the future's value.
  void debugFutureType<T>() {
    serviceFuture.then((value) {
      // tempInstance = value;
      print('Expected type: $T, actual type: ${value.runtimeType}');
      if (value is T) {
        print('The future completes with the expected type.');
      } else {
        print('Type mismatch. The future does not complete with the expected type.');
      }
    });
  }

  InjectorInjectableInstanceScopeContainer forReference({String? name}) => InjectorInjectableInstanceScopeContainer(
        parentInjectorId,
        serviceFuture,
        name: name ?? this.name,
      );
}
