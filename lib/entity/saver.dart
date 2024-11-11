class Saver {
  final List<String> paths;
  final String name;
  final int? color;
  final int count;
  final String? photoName;
  final int suffixType;

  const Saver(
      {required this.paths,
      required this.name,
      this.color,
      this.count = 0,
      this.photoName,
      this.suffixType = 0});
}
