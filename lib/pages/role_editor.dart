import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models.dart';

class RoleEditorPage extends StatefulWidget {
  final Role? role;

  const RoleEditorPage({super.key, this.role});

  @override
  State<RoleEditorPage> createState() => _RoleEditorPageState();
}

class _RoleEditorPageState extends State<RoleEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();

  late TextEditingController _nameController;
  late TextEditingController _displayNameController;
  late TextEditingController _descriptionController;
  late List<Permission> _permissions;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.role?.name);
    _displayNameController =
        TextEditingController(text: widget.role?.displayName);
    _descriptionController =
        TextEditingController(text: widget.role?.description);
    _permissions = List<Permission>.from(widget.role?.permissions ?? []);
    _isActive = widget.role?.isActive ?? true;
  }

  void _showAddPermissionDialog() {
    final resourceController = TextEditingController();
    final actionController = TextEditingController();
    final scopeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Permission'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: resourceController,
                  decoration: const InputDecoration(labelText: 'Resource'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: actionController,
                  decoration: const InputDecoration(labelText: 'Action'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: scopeController,
                  decoration: const InputDecoration(labelText: 'Scope'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    _permissions.add(Permission(
                      resource: resourceController.text,
                      action: actionController.text,
                      scope: scopeController.text,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Permissions', style: Theme.of(context).textTheme.titleLarge),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddPermissionDialog,
            ),
          ],
        ),
        if (_permissions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No permissions for this role.'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _permissions.length,
            itemBuilder: (context, index) {
              final p = _permissions[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text('Resource: ${p.resource}'),
                  subtitle: Text('Action: ${p.action}, Scope: ${p.scope}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _permissions.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.role == null ? '新增角色' : '編輯角色'),
        actions: [
          if (widget.role != null && !(widget.role?.isSystemDefault ?? false))
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('刪除角色?'),
                    content: const Text('你確定要刪除此角色嗎?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('刪除'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await _apiClient.deleteRole(widget.role!.id);
                    Navigator.pop(context, true); // Return true to indicate success
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete role: $e')),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '角色名稱 (英文)'),
                readOnly: widget.role?.isSystemDefault ?? false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入角色名稱';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(labelText: '顯示名稱'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入顯示名稱';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '描述'),
              ),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (widget.role?.isSystemDefault ?? false)
                    ? null
                    : (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
              ),
              const SizedBox(height: 20),
              _buildPermissionsSection(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final role = Role(
                      id: widget.role?.id ?? 0,
                      name: _nameController.text,
                      displayName: _displayNameController.text,
                      description: _descriptionController.text,
                      permissions: _permissions,
                      isActive: _isActive,
                      isSystemDefault: widget.role?.isSystemDefault ?? false,
                      createdAt: widget.role?.createdAt ?? '',
                    );

                    try {
                      if (widget.role == null) {
                        await _apiClient.createRole(role);
                      } else {
                        await _apiClient.updateRole(role);
                      }
                      Navigator.pop(context, true); // Return true to indicate success
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save role: $e')),
                      );
                    }
                  }
                },
                child: const Text('儲存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
