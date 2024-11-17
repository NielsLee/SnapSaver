class More {
  final String? photoName;
  /**
   * 0: index
   * 1: timeStamp
   * 2: _index
   * 3: _timeStamp
   * 4: -index
   * 5: -timeStamp
   */
  final int suffixType;

  const More({this.photoName, this.suffixType = 0});
}
