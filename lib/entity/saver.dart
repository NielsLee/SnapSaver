class Saver {
  final String path;
  final String name;

  const Saver({required this.path, required this.name});

  Map<String, Object?> toMap() {
    return {
      'path': path,
      'name': name
    };
  }
}
