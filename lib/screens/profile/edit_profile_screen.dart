import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/avatar_utils.dart';
import '../../widgets/common/gradient_button.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _handleCtrl;
  late final TextEditingController _taglineCtrl;
  late final TextEditingController _bioCtrl;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _currentAvatarUrl = widget.user.avatarUrl;
    _handleCtrl = TextEditingController(text: widget.user.handle);
    _taglineCtrl = TextEditingController(text: widget.user.tagline ?? '');
    _bioCtrl = TextEditingController(text: widget.user.bio ?? '');
  }

  @override
  void dispose() {
    _handleCtrl.dispose();
    _taglineCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last.toLowerCase();
      final mimeExt = ext == 'jpg' ? 'jpeg' : ext;
      // Always store as .jpg so the path never changes between picks
      final path = '${widget.user.id}.jpg';
      await SupabaseService.uploadAvatar(path, bytes, mimeExt);
      // Cache-bust so the app shows the new image immediately
      final url =
          '${SupabaseService.getAvatarPublicUrl(path)}?t=${DateTime.now().millisecondsSinceEpoch}';
      await context.read<AuthProvider>().updateProfile(avatarUrl: url);
      if (mounted) setState(() => _currentAvatarUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    final handle = _handleCtrl.text.trim();
    if (handle.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Handle must be at least 3 characters')),
      );
      return;
    }
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(handle)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Handle: only lowercase letters, numbers, underscores')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateProfile(
            handle: handle,
            tagline: _taglineCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.of(context).surfaceVariant,
        title: const Text('Sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) await context.read<AuthProvider>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.of(context).surface,
      appBar: AppBar(
        backgroundColor: AppTheme.of(context).surfaceVariant,
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _uploadingAvatar ? null : _pickAvatar,
                child: Stack(
                  children: [
                    _uploadingAvatar
                        ? Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: AppTheme.of(context).surfaceVariant,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppTheme.primary),
                            ),
                          )
                        : AvatarUtils.buildAvatar(
                            url: _currentAvatarUrl,
                            userId: widget.user.id,
                            username: widget.user.handle,
                            radius: 48,
                          ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                            color: AppTheme.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Badge display
            Builder(builder: (context) {
              final badge = widget.user.badge;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(badge.emoji),
                  const SizedBox(width: 4),
                  Text(
                    badge.name,
                    style: TextStyle(color: badge.color, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· ${widget.user.userScore} pts',
                    style: TextStyle(color: AppTheme.of(context).onSurfaceMuted, fontSize: 12),
                  ),
                ],
              );
            }),
            const SizedBox(height: 32),
            TextFormField(
              controller: _handleCtrl,
              decoration: InputDecoration(
                labelText: 'Handle',
                prefixText: '@',
                prefixIcon: Icon(Icons.alternate_email, color: AppTheme.of(context).onSurfaceMuted),
                helperText: 'Lowercase, letters/numbers/underscores only',
                helperStyle: TextStyle(fontSize: 11),
              ),
              onChanged: (v) {
                final clean = v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
                if (clean != v) {
                  _handleCtrl.value = _handleCtrl.value.copyWith(
                    text: clean,
                    selection: TextSelection.collapsed(offset: clean.length),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _taglineCtrl,
              maxLength: 60,
              decoration: InputDecoration(
                labelText: 'Tagline',
                prefixIcon: Icon(Icons.format_quote, color: AppTheme.of(context).onSurfaceMuted),
                hintText: 'e.g. Long-term investor · Nifty analyst',
                counterStyle: TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioCtrl,
              maxLines: 3,
              maxLength: 150,
              decoration: InputDecoration(
                labelText: 'Bio',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes, color: AppTheme.of(context).onSurfaceMuted),
              ),
            ),
            const SizedBox(height: 28),
            GradientButton(label: 'Save Changes', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
