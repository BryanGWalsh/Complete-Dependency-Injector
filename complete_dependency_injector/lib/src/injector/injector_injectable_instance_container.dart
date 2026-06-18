class InjectorInjectableInstanceScopeContainer {
  final int parentInjectorId;
  final Future<Object> serviceFuture;
  final String? name;

  InjectorInjectableInstanceScopeContainer(
    this.parentInjectorId,
    this.serviceFuture, {
    this.name,
  });

  InjectorInjectableInstanceScopeContainer forReference({String? name}) => InjectorInjectableInstanceScopeContainer(
        parentInjectorId,
        serviceFuture,
        name: name ?? this.name,
      );
}
