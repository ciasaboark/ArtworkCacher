part of artworkCacher.exception;

class NullArgumentException {
  final String msg;
  
  NullArgumentException(String this.msg);
  
  @override String toString() => msg;
}