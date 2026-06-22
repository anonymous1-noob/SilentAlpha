import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
  late final TextEditingController _taglineCtrl;
  late final TextEditingController _bioCtrl;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _currentAvatarUrl = widget.user.avatarUrl;
    _taglineCtrl = TextEditingController(text: widget.user.tagline ?? '');
    _bioCtrl = TextEditingController(text: widget.user.bio ?? '');
  }

  @override
  void dispose() {
    _taglineCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    final original = await picked.readAsBytes();
    const maxSizeBytes = 5 * 1024 * 1024;
    if (original.length > maxSizeBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image must be under 5 MB')),
        );
      }
      return;
    }

    setState(() => _uploadingAvatar = true);
    try {
      // Compress to ≤ 100 KB at 512×512 max
      Uint8List compressed = original;
      int quality = 60;
      while (compressed.length > 100 * 1024 && quality >= 10) {
        compressed = await FlutterImageCompress.compressWithList(
          original,
          minWidth: 512,
          minHeight: 512,
          quality: quality,
          format: CompressFormat.jpeg,
        );
        quality -= 15;
      }

      const path_suffix = '.jpg';
      final path = '${widget.user.id}$path_suffix';
      await SupabaseService.uploadAvatar(path, compressed, 'jpeg');
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
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateProfile(
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
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.of(context).surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.of(context).border),
              ),
              child: Row(
                children: [
                  Icon(Icons.alternate_email, size: 20, color: AppTheme.of(context).onSurfaceMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Handle',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.of(context).onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${widget.user.handle}',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.of(context).onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.lock_outline, size: 16, color: AppTheme.of(context).onSurfaceMuted),
                ],
              ),
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
