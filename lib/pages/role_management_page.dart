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
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _deleteRole(Role role) async {
    // Don't allow deletion of system default roles
    if (role.isSystemDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法刪除系統預設角色')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const SelectableText('確認刪除'),
        content: SelectableText('確定要刪除角色「${role.displayName}」嗎？\n此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiClient.deleteRole(role.id);
        _loadRoles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('角色「${role.displayName}」已刪除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('刪除失敗: $e')),
          );
        }
      }
    }
  }

  void _showRoleDetails(Role role) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      role.displayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('系統名稱', role.name),
              _buildDetailRow('描述', role.description.isNotEmpty ? role.description : '無'),
              _buildDetailRow('狀態', role.isActive ? '啟用' : '停用'),
              _buildDetailRow('類型', role.isSystemDefault ? '系統預設' : '自定義'),
              _buildDetailRow('建立時間', role.createdAt),
              const SizedBox(height: 16),
              const SelectableText(
                '權限列表',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (role.permissions.isEmpty)
                const SelectableText('此角色沒有設定任何權限')
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Column(
                      children: role.permissions.map((p) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          dense: true,
                          title: SelectableText('資源: ${p.resource}'),
                          subtitle: SelectableText('動作: ${p.action}, 範圍: ${p.scope}'),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('關閉'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _navigateToEditor(role);
                    },
                    child: const Text('編輯'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: SelectableText(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('角色管理'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoles,
            tooltip: '重新載入',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToEditor(),
            tooltip: '新增角色',
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  SelectableText('載入角色失敗: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadRoles,
                    child: const Text('重試'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const SelectableText('尚無角色資料'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('新增第一個角色'),
                  ),
                ],
              ),
            );
          }

          final roles = snapshot.data!;
          
          // 使用 DataTable 顯示
          return SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('顯示名稱')),
                  DataColumn(label: Text('系統名稱')),
                  DataColumn(label: Text('描述')),
                  DataColumn(label: Text('權限數')),
                  DataColumn(label: Text('狀態')),
                  DataColumn(label: Text('類型')),
                  DataColumn(label: Text('操作')),
                ],
                rows: roles.map((role) {
                  return DataRow(
                    cells: [
                      DataCell(SelectableText(role.id.toString())),
                      DataCell(
                        Row(
                          children: [
                            SelectableText(
                              role.displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      DataCell(SelectableText(role.name)),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: SelectableText(
                            role.description.isNotEmpty ? role.description : '-',
                            maxLines: 2,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: role.permissions.isEmpty 
                                ? Colors.grey.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${role.permissions.length} 個',
                            style: TextStyle(
                              fontSize: 12,
                              color: role.permissions.isEmpty ? Colors.grey : Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            Icon(
                              role.isActive ? Icons.check_circle : Icons.cancel,
                              size: 20,
                              color: role.isActive ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              role.isActive ? '啟用' : '停用',
                              style: TextStyle(
                                color: role.isActive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: role.isSystemDefault 
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: role.isSystemDefault ? Colors.blue : Colors.green,
                            ),
                          ),
                          child: Text(
                            role.isSystemDefault ? '系統預設' : '自定義',
                            style: TextStyle(
                              fontSize: 12,
                              color: role.isSystemDefault ? Colors.blue : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _showRoleDetails(role),
                              tooltip: '查看詳情',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _navigateToEditor(role),
                              tooltip: '編輯',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: role.isSystemDefault ? Colors.grey : Colors.red,
                              ),
                              onPressed: role.isSystemDefault 
                                  ? null 
                                  : () => _deleteRole(role),
                              tooltip: role.isSystemDefault ? '系統角色無法刪除' : '刪除',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditor(),
        child: const Icon(Icons.add),
        tooltip: '新增角色',
      ),
    );
  }
}