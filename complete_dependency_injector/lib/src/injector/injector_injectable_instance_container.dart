class InjectorInjectableInstanceScopeContainer {
  final int parentInjectorId;
  final Future<Object?> serviceFuture;
  final String? name;

  /// True for the `null` an optional lookup gets when nothing provides the
  /// token.
  final bool unprovided;

  InjectorInjectableInstanceScopeContainer(
    this.parentInjectorId,
    this.serviceFuture, {
    this.name,
    this.unprovided = false,
  });

  InjectorInjectableInstanceScopeContainer forReference({String? name}) => InjectorInjectableInstanceScopeContainer(
        parentInjectorId,
        serviceFuture,
        name: name ?? this.name,
        unprovided: unprovided,
      );
}
