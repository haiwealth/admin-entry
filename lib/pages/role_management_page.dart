import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models.dart';
import 'role_editor.dart';

class RoleManagementPage extends StatefulWidget {
  const RoleManagementPage({super.key});

  @override
  State<RoleManagementPage> createState() => _RoleManagementPageState();
}

class _RoleManagementPageState extends State<RoleManagementPage> {
  final _apiClient = ApiClient();
  late Future<List<Role>> _roles;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  void _loadRoles() {
    setState(() {
      _roles = _apiClient.getRoles();
    });
  }

  void _navigateToEditor([Role? role]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RoleEditorPage(role: role),
      ),
    );

    if (result == true) {
      _loadRoles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('角色管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoles,
          ),
        ],
      ),
      body: FutureBuilder<List<Role>>(
        future: _roles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: SelectableText('Failed to load roles: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: SelectableText('No roles found.'));
          }

          final roles = snapshot.data!;
          return ListView.builder(
            itemCount: roles.length,
            itemBuilder: (context, index) {
              final role = roles[index];
              return ListTile(
                title: SelectableText(role.displayName),
                subtitle: SelectableText(role.name),
                trailing: Icon(
                  role.isActive ? Icons.check_circle : Icons.cancel,
                  color: role.isActive ? Colors.green : Colors.red,
                ),
                onTap: () => _navigateToEditor(role),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
