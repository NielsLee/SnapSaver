class Saver {
  final List<String> paths;
  final String name;
  // TODO implement Saver colors
  final int? color;

  const Saver({required this.paths, required this.name, this.color});

  Map<String, Object?> toMap() {
    return {
      'path': paths,
      'name': name,
      'color': color,
    };
  }
}
