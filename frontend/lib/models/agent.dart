class Agent {
  final String id;
  final String name;
  final String? role;

  Agent({required this.id, required this.name, this.role});
  factory Agent.fromJson(Map<String, dynamic> j) => Agent(
        id: j['id'].toString(),
        name: (j['name'] ?? j['full_name'] ?? 'Unnamed').toString(),
        role: j['role']?.toString(),
      );

  @override
  String toString() => name;
}