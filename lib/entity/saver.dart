class Saver {
  final String path;
  final String name;
  // TODO implement Saver colors
  final String? color;

  const Saver({required this.path, required this.name, this.color});

  Map<String, Object?> toMap() {
    return {
      'path': path,
      'name': name,
      'color': color,
    };
  }
}
