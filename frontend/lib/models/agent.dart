class Agent {
  final String id;
  final String name;
  final String? role;

  Agent({required this.id, required this.name, this.role});

  /// ASSUMPTION: agents are rows in `profiles` with role == 'agent'.
  /// Rename keys / table if agents live somewhere else in your schema.
  factory Agent.fromJson(Map<String, dynamic> j) => Agent(
        id: j['id'].toString(),
        name: (j['name'] ?? j['full_name'] ?? 'Unnamed').toString(),
        role: j['role']?.toString(),
      );

  @override
  String toString() => name;
}