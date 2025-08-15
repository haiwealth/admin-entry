import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models.dart';
import 'role_editor.dart';

class PermissionManagementPage extends StatefulWidget {
  const PermissionManagementPage({super.key});

  @override
  State<PermissionManagementPage> createState() =>
      _PermissionManagementPageState();
}

class _PermissionManagementPageState extends State<PermissionManagementPage> {
  final _apiClient = ApiClient();
  late Future<List<Role>> _rolesFuture;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  void _loadRoles() {
    setState(() {
      _rolesFuture = _apiClient.getRoles();
    });
  }

  void _navigateToEditor(Role role) async {
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
        title: const Text('權限總覽'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoles,
          ),
        ],
      ),
      body: FutureBuilder<List<Role>>(
        future: _rolesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Failed to load permissions: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No roles found.'));
          }

          final roles = snapshot.data!;
          return ListView.builder(
            itemCount: roles.length,
            itemBuilder: (context, index) {
              final role = roles[index];
              return ExpansionTile(
                title: Text(role.displayName),
                subtitle: Text(role.name),
                leading: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _navigateToEditor(role),
                ),
                children: role.permissions.isEmpty
                    ? [const ListTile(title: Text('No permissions assigned.'))]
                    : role.permissions.map((p) {
                        return ListTile(
                          title: Text('Resource: ${p.resource}'),
                          subtitle:
                              Text('Action: ${p.action}, Scope: ${p.scope}'),
                          dense: true,
                        );
                      }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
