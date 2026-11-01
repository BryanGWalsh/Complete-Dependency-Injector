import 'injector_token_interface.dart';

class InjectorToken implements InjectorTokenInterface {
  final String _tokenStringRepresentation;
  static int _uniqueTokenCreationIdentifierCounter = 1;

  InjectorToken.fromCounter()
      : _tokenStringRepresentation = "counter_$_uniqueTokenCreationIdentifierCounter"{
    _uniqueTokenCreationIdentifierCounter++;
  }

  InjectorToken.fromString(String identifier)
      : _tokenStringRepresentation = "string_$identifier";

  InjectorToken.fromType(Type classType)
      : _tokenStringRepresentation = "type_$classType-${classType.hashCode}";

  static InjectorToken fromTokenOrType(Object tokenOrInjectableClass){
    if(tokenOrInjectableClass.runtimeType == InjectorToken) return tokenOrInjectableClass as InjectorToken;
    return InjectorToken.fromType(tokenOrInjectableClass as Type);
  }
  @override
  String get tokenRepresentation => _tokenStringRepresentation;
}