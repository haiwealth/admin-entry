import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _apiClient = ApiClient();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<User> _users = [];
  List<Role> _roles = [];
  int _currentPage = 1;
  int _totalUsers = 0;
  final int _itemsPerPage = 10;
  bool _isLoading = false;
  String? _selectedProvider;
  int? _selectedRoleId;

  @override
  void initState() {
    super.initState();
    _loadRoles();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await _apiClient.getRoles();
      setState(() {
        _roles = roles;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入角色失敗: $e')),
        );
      }
    }
  }

  Future<void> _loadUsers() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiClient.getUsers(
        page: _currentPage,
        limit: _itemsPerPage,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        roleId: _selectedRoleId,
        provider: _selectedProvider,
      );

      setState(() {
        _users = result['users'];
        _totalUsers = result['total'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入用戶失敗: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to get role for a user
  Role? _getRoleForUser(User user) {
    if (user.role != null && user.role!.id > 0) {
      // Try to find the role by ID in our roles list
      try {
        return _roles.firstWhere((r) => r.id == user.role!.id);
      } catch (e) {
        // If not found, return the user's role as is
        return user.role;
      }
    }
    return user.role;
  }
  
  // Helper method to get role display name
  String _getRoleDisplayName(User user) {
    final role = _getRoleForUser(user);
    if (role != null) {
      return role.displayName;
    }
    // Fallback display names
    if (user.role?.name != null) {
      switch (user.role!.name.toLowerCase()) {
        case 'admin':
          return '管理員';
        case 'instructor':
          return '講師';
        case 'student':
          return '學生';
        default:
          return user.role!.name;
      }
    }
    return '未設定';
  }

  void _showUserDetailDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => UserDetailDialog(
        user: user,
        roles: _roles,
        onUserUpdated: () {
          _loadUsers();
        },
      ),
    );
  }

  int get _totalPages => (_totalUsers / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用戶管理'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 搜尋和篩選區域
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: '搜尋用戶',
                      hintText: '輸入名稱或Email',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _currentPage = 1;
                                _loadUsers();
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (value) {
                      _currentPage = 1;
                      _loadUsers();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // 角色篩選
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedRoleId,
                    decoration: const InputDecoration(
                      labelText: '角色篩選',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('全部角色'),
                      ),
                      ..._roles.map((role) => DropdownMenuItem(
                        value: role.id,
                        child: Text(role.displayName),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRoleId = value;
                        _currentPage = 1;
                      });
                      _loadUsers();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // 登入方式篩選
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedProvider,
                    decoration: const InputDecoration(
                      labelText: '登入方式',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('全部'),
                      ),
                      DropdownMenuItem(
                        value: 'email',
                        child: Text('Email'),
                      ),
                      DropdownMenuItem(
                        value: 'google',
                        child: Text('Google'),
                      ),
                      DropdownMenuItem(
                        value: 'facebook',
                        child: Text('Facebook'),
                      ),
                      DropdownMenuItem(
                        value: 'line',
                        child: Text('LINE'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedProvider = value;
                        _currentPage = 1;
                      });
                      _loadUsers();
                    },
                  ),
                ),
              ],
            ),
          ),
          // 用戶列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(
                        child: Text('沒有找到用戶'),
                      )
                    : SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('用戶名')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('姓名')),
                            DataColumn(label: Text('角色')),
                            DataColumn(label: Text('登入方式')),
                            DataColumn(label: Text('狀態')),
                            DataColumn(label: Text('登入次數')),
                            DataColumn(label: Text('最後登入')),
                            DataColumn(label: Text('操作')),
                          ],
                          rows: _users.map((user) {
                            final loginMethods = user.loginMethods?.map((m) => m.provider).join(', ') ?? 'email';
                            return DataRow(
                              cells: [
                                DataCell(SelectableText(user.id.toString())),
                                DataCell(SelectableText(user.username)),
                                DataCell(SelectableText(user.email)),
                                DataCell(SelectableText('${user.firstName} ${user.lastName}')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(user.role?.name),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: SelectableText(
                                      _getRoleDisplayName(user),
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ),
                                DataCell(SelectableText(loginMethods)),
                                DataCell(
                                  Icon(
                                    user.isActive ?? true ? Icons.check_circle : Icons.cancel,
                                    color: user.isActive ?? true ? Colors.green : Colors.red,
                                  ),
                                ),
                                DataCell(SelectableText(user.loginCount?.toString() ?? '0')),
                                DataCell(SelectableText(_formatDate(user.lastLoginAt))),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility),
                                        onPressed: () => _showUserDetailDialog(user),
                                        tooltip: '查看詳情',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _showEditUserDialog(user),
                                        tooltip: '編輯',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.lock_reset),
                                        onPressed: () => _showResetPasswordDialog(user),
                                        tooltip: '重置密碼',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _confirmDeleteUser(user),
                                        tooltip: '刪除',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
          ),
          // 分頁控制
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                            _loadUsers();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  ...List.generate(
                    _totalPages > 5 ? 5 : _totalPages,
                    (index) {
                      int pageNumber;
                      if (_totalPages <= 5) {
                        pageNumber = index + 1;
                      } else {
                        if (_currentPage <= 3) {
                          pageNumber = index + 1;
                        } else if (_currentPage >= _totalPages - 2) {
                          pageNumber = _totalPages - 4 + index;
                        } else {
                          pageNumber = _currentPage - 2 + index;
                        }
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: pageNumber != _currentPage
                              ? () {
                                  setState(() {
                                    _currentPage = pageNumber;
                                  });
                                  _loadUsers();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pageNumber == _currentPage
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          child: Text(
                            pageNumber.toString(),
                            style: TextStyle(
                              color: pageNumber == _currentPage
                                  ? Colors.white
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    onPressed: _currentPage < _totalPages
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                            _loadUsers();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                  const SizedBox(width: 16),
                  SelectableText('共 $_totalUsers 位用戶'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'instructor':
        return Colors.blue;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '從未登入';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showEditUserDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => EditUserDialog(
        user: user,
        roles: _roles,
        onUserUpdated: () {
          _loadUsers();
        },
      ),
    );
  }

  void _showResetPasswordDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => ResetPasswordDialog(
        user: user,
        onPasswordReset: () {
          _loadUsers();
        },
      ),
    );
  }

  void _confirmDeleteUser(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const SelectableText('確認刪除'),
        content: SelectableText('確定要刪除用戶 ${user.username} (${user.email}) 嗎？\n此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _apiClient.deleteUser(user.id);
                _loadUsers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('用戶已刪除')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('刪除失敗: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }
}

// 用戶詳情對話框
class UserDetailDialog extends StatefulWidget {
  final User user;
  final List<Role> roles;
  final VoidCallback onUserUpdated;

  const UserDetailDialog({
    super.key,
    required this.user,
    required this.roles,
    required this.onUserUpdated,
  });

  @override
  State<UserDetailDialog> createState() => _UserDetailDialogState();
}

class _UserDetailDialogState extends State<UserDetailDialog> {
  late User _user;
  final _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    try {
      final user = await _apiClient.getUserById(widget.user.id);
      setState(() {
        _user = user;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入用戶詳情失敗: $e')),
        );
      }
    }
  }
  
  // Helper method to get role display name
  String _getRoleDisplayName(User user) {
    if (user.role != null) {
      // Try to find the role in the provided roles list
      if (user.role!.id > 0 && widget.roles.isNotEmpty) {
        try {
          final role = widget.roles.firstWhere((r) => r.id == user.role!.id);
          return role.displayName;
        } catch (e) {
          // Role not found in list
        }
      }
      // Use the role's display name if available
      if (user.role!.displayName.isNotEmpty) {
        return user.role!.displayName;
      }
      // Fallback to role name
      return user.role!.name;
    }
    return '未設定';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_user.avatar != null)
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(_user.avatar!),
                  )
                else
                  const CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 30),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        '${_user.firstName} ${_user.lastName}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SelectableText(
                        _user.username,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow('ID', _user.id.toString()),
            _buildInfoRow('Email', _user.email),
            _buildInfoRow('角色', _getRoleDisplayName(_user)),
            _buildInfoRow('狀態', _user.isActive ?? true ? '啟用' : '停用'),
            _buildInfoRow('註冊日期', _formatDate(_user.registrationDate)),
            _buildInfoRow('最後登入', _formatDate(_user.lastLoginAt)),
            _buildInfoRow('登入次數', _user.loginCount?.toString() ?? '0'),
            _buildInfoRow('課程註冊數', _user.totalCourseEnrollments?.toString() ?? '0'),
            if (_user.loginMethods != null && _user.loginMethods!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const SelectableText(
                '認證方法',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._user.loginMethods!.map((method) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(
                    _getProviderIcon(method.provider),
                    color: method.isActive ? Colors.green : Colors.grey,
                  ),
                  title: SelectableText(method.providerName ?? method.provider),
                  subtitle: SelectableText('建立於: ${_formatDate(method.createdAt)}'),
                  trailing: Switch(
                    value: method.isActive,
                    onChanged: null, // 在詳情視圖中不允許修改
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '無資料';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  IconData _getProviderIcon(String provider) {
    switch (provider) {
      case 'google':
        return Icons.g_mobiledata;
      case 'facebook':
        return Icons.facebook;
      case 'line':
        return Icons.chat;
      case 'email':
        return Icons.email;
      default:
        return Icons.login;
    }
  }
}

// 編輯用戶對話框
class EditUserDialog extends StatefulWidget {
  final User user;
  final List<Role> roles;
  final VoidCallback onUserUpdated;

  const EditUserDialog({
    super.key,
    required this.user,
    required this.roles,
    required this.onUserUpdated,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _avatarController;
  int? _selectedRoleId;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user.email);
    _usernameController = TextEditingController(text: widget.user.username);
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _avatarController = TextEditingController(text: widget.user.avatar);
    
    // Try to get the correct role ID
    if (widget.user.role != null) {
      if (widget.user.role!.id > 0) {
        _selectedRoleId = widget.user.role!.id;
      } else {
        // Try to find role by name if ID is not valid
        try {
          final matchingRole = widget.roles.firstWhere(
            (r) => r.name.toLowerCase() == widget.user.role!.name.toLowerCase(),
          );
          _selectedRoleId = matchingRole.id;
        } catch (e) {
          _selectedRoleId = null;
        }
      }
    } else {
      _selectedRoleId = null;
    }
    
    _isActive = widget.user.isActive ?? true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiClient.updateUser(widget.user.id, {
        'email': _emailController.text,
        'username': _usernameController.text,
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'avatar': _avatarController.text.isNotEmpty ? _avatarController.text : null,
        'role_id': _selectedRoleId,
        'is_active': _isActive,
      });

      widget.onUserUpdated();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('用戶資料已更新')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失敗: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                '編輯用戶',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入Email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return '請輸入有效的Email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用戶名',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入用戶名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: '名字',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: '姓氏',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _avatarController,
                decoration: const InputDecoration(
                  labelText: '頭像URL（選填）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedRoleId,
                decoration: const InputDecoration(
                  labelText: '角色',
                  border: OutlineInputBorder(),
                ),
                items: widget.roles.map((role) => DropdownMenuItem(
                  value: role.id,
                  child: Text(role.displayName),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRoleId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return '請選擇角色';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('帳號狀態'),
                subtitle: Text(_isActive ? '啟用' : '停用'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveUser,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('儲存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 重置密碼對話框
class ResetPasswordDialog extends StatefulWidget {
  final User user;
  final VoidCallback onPasswordReset;

  const ResetPasswordDialog({
    super.key,
    required this.user,
    required this.onPasswordReset,
  });

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _sendEmail = true;
  bool _requireChange = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiClient.resetUserPassword(
        widget.user.id,
        _passwordController.text,
        sendEmail: _sendEmail,
        requireChange: _requireChange,
      );

      widget.onPasswordReset();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('密碼已重置')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('重置失敗: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                '重置密碼',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              SelectableText(
                '用戶: ${widget.user.username} (${widget.user.email})',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '新密碼',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入新密碼';
                  }
                  if (value.length < 6) {
                    return '密碼長度至少6個字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '確認密碼',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請確認密碼';
                  }
                  if (value != _passwordController.text) {
                    return '密碼不匹配';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('發送Email通知'),
                value: _sendEmail,
                onChanged: (value) {
                  setState(() {
                    _sendEmail = value ?? true;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('要求用戶下次登入時修改密碼'),
                value: _requireChange,
                onChanged: (value) {
                  setState(() {
                    _requireChange = value ?? true;
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('重置密碼'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}