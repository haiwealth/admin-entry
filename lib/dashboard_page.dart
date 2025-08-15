import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'pages/course_list_page.dart';
import 'pages/user_management_page.dart';
import 'pages/role_management_page.dart';
import 'pages/permission_management_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理後台'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildDashboardItem(context, '課程管理', Icons.book, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CourseListPage()),
            );
          }),
          _buildDashboardItem(context, '使用者管理', Icons.people, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const UserManagementPage()),
            );
          }),
          _buildDashboardItem(context, '角色管理', Icons.security, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const RoleManagementPage()),
            );
          }),
          _buildDashboardItem(context, '權限管理', Icons.vpn_key, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const PermissionManagementPage()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 48.0),
            const SizedBox(height: 8.0),
            SelectableText(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
