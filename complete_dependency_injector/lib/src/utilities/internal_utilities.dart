
import '../library_src.dart';

abstract class SDIInternalUtilities{



  static bool isPrimitiveTypeOrNull(dynamic item) =>  item is! int && item is! double && item is! String && item is! bool && item !=null;
  static bool isNotPrimitiveTypeOrNull(Object item) => !SDIInternalUtilities.isPrimitiveTypeOrNull(item);

}