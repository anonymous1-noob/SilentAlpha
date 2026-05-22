import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/gradient_button.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceVariant,
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (b) => AppTheme.gradient.createShader(b),
              child: const Icon(Icons.shield, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.onSurfaceMuted,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.category_outlined, size: 18), text: 'Categories'),
            Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _CategoriesTab(),
          _UsersTab(),
        ],
      ),
    );
  }
}

// ── Categories tab ────────────────────────────────────────────────────────────

class _CategoriesTab extends StatefulWidget {
  const _CategoriesTab();

  @override
  State<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<_CategoriesTab> {
  List<Map<String, dynamic>> _cats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _cats = await SupabaseService.getCategories();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: const Text('New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emojiCtrl,
              decoration: const InputDecoration(hintText: 'Emoji (e.g. 📊)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(hintText: 'Category name'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              try {
                await SupabaseService.createCategory(
                  name: name,
                  emoji: emojiCtrl.text.trim().isEmpty ? null : emojiCtrl.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
                _load();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> cat) {
    final nameCtrl = TextEditingController(text: cat['name'] as String);
    final emojiCtrl = TextEditingController(text: cat['emoji'] as String? ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: const Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emojiCtrl,
              decoration: const InputDecoration(hintText: 'Emoji'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(hintText: 'Category name'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await SupabaseService.updateCategory(
                  cat['id'] as String,
                  name: nameCtrl.text.trim(),
                  emoji: emojiCtrl.text.trim().isEmpty ? null : emojiCtrl.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
                _load();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: const Text('Delete category?'),
        content: Text('Delete "${cat['name']}"? Posts in this category will lose their category tag.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.deleteCategory(cat['id'] as String);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: GradientButton(
            label: '+ Add Category',
            onPressed: _showAddDialog,
            icon: Icons.add,
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _cats.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF1A2545)),
            itemBuilder: (_, i) {
              final cat = _cats[i];
              return FadeInUp(
                delay: Duration(milliseconds: i * 40),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(cat['emoji'] as String? ?? '📌',
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  title: Text(cat['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${(cat['post_count'] ?? 0)} posts',
                      style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                        onPressed: () => _showEditDialog(cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        onPressed: () => _delete(cat),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Users tab ─────────────────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _users = await SupabaseService.getAllUsers();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleRole(Map<String, dynamic> user) async {
    final isAdmin = (user['role'] as String?) == 'admin';
    final newRole = isAdmin ? 'user' : 'admin';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: Text(isAdmin ? 'Remove admin?' : 'Make admin?'),
        content: Text(
          isAdmin
              ? '@${user['handle']} will lose admin privileges.'
              : '@${user['handle']} will get full admin access.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: isAdmin ? Colors.red : AppTheme.primary),
            child: Text(isAdmin ? 'Remove' : 'Grant',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.setUserRole(user['id'] as String, newRole);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF1A2545)),
      itemBuilder: (_, i) {
        final user = _users[i];
        final isAdmin = (user['role'] as String?) == 'admin';
        final isSelf = user['id'] == SupabaseService.currentUserId;
        return FadeInUp(
          delay: Duration(milliseconds: i * 40),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isAdmin
                  ? AppTheme.primary.withValues(alpha: 0.2)
                  : AppTheme.onSurfaceMuted.withValues(alpha: 0.1),
              child: Text(
                '@',
                style: TextStyle(
                  color: isAdmin ? AppTheme.primary : AppTheme.onSurfaceMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Row(
              children: [
                Text('@${user['handle'] ?? 'unknown'}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (isSelf) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('you',
                        style: TextStyle(fontSize: 9, color: AppTheme.primary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              isAdmin ? '🛡️ Admin' : 'User',
              style: TextStyle(
                color: isAdmin ? AppTheme.primary : AppTheme.onSurfaceMuted,
                fontSize: 12,
                fontWeight: isAdmin ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: isSelf
                ? null
                : TextButton(
                    onPressed: () => _toggleRole(user),
                    style: TextButton.styleFrom(
                      foregroundColor: isAdmin ? Colors.red : AppTheme.primary,
                    ),
                    child: Text(isAdmin ? 'Remove admin' : 'Make admin',
                        style: const TextStyle(fontSize: 12)),
                  ),
          ),
        );
      },
    );
  }
}
