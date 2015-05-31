part of salix.exception;

class NullArgumentException {
  final String msg;
  
  NullArgumentException(String this.msg);
  
  @override String toString() => msg;
}