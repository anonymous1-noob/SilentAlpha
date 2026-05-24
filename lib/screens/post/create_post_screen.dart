import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/categories_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/hashtag_utils.dart';
import '../../widgets/common/gradient_button.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentCtrl = TextEditingController();
  final _pollQuestionCtrl = TextEditingController();
  final List<TextEditingController> _pollOptionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];

  String? _selectedCategoryId;
  bool _sending = false;
  bool _isAnonymous = false;
  List<String> _hashtags = [];
  // Image
  Uint8List? _imageBytes;
  String? _imageExt;

  // Poll
  bool _addPoll = false;
  DateTime? _pollDeadline;

  static const _draftKey = 'create_post_draft';
  Timer? _draftTimer;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
    _contentCtrl.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _contentCtrl.removeListener(_onContentChanged);
    _contentCtrl.dispose();
    _pollQuestionCtrl.dispose();
    for (final c in _pollOptionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _onContentChanged() {
    final text = _contentCtrl.text;
    final tags = HashtagUtils.extractNormalized(text);
    if (tags.toString() != _hashtags.toString()) {
      setState(() {
        _hashtags = tags;
      });
    }
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 500), () => _saveDraft(text));
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = prefs.getString(_draftKey);
    if (draft != null && draft.isNotEmpty && mounted) {
      _contentCtrl.text = draft;
      _contentCtrl.selection =
          TextSelection.collapsed(offset: draft.length);
    }
  }

  Future<void> _saveDraft(String text) async {
    final prefs = await SharedPreferences.getInstance();
    if (text.isEmpty) {
      await prefs.remove(_draftKey);
    } else {
      await prefs.setString(_draftKey, text);
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  void _autoSelectCategory(List cats) {
    if (cats.isEmpty) return;
    if (_selectedCategoryId == null ||
        !cats.any((c) => c.id == _selectedCategoryId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedCategoryId = cats.first.id);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final original = await file.readAsBytes();
    const maxSizeBytes = 5 * 1024 * 1024; // 5 MB
    if (original.length > maxSizeBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image must be under 5 MB')),
        );
      }
      return;
    }

    final ext = file.name.split('.').last.toLowerCase();
    // Compress to under 100 KB, iterating quality down until target is met
    Uint8List compressed = original;
    int quality = 60;
    while (compressed.length > 100 * 1024 && quality >= 10) {
      compressed = await FlutterImageCompress.compressWithList(
        original,
        minWidth: 800,
        minHeight: 800,
        quality: quality,
        format: ext == 'png' ? CompressFormat.png : CompressFormat.jpeg,
      );
      quality -= 15;
    }

    setState(() {
      _imageBytes = compressed;
      _imageExt = ext == 'png' ? 'png' : 'jpg';
    });
  }

  void _addPollOption() {
    if (_pollOptionCtrls.length >= 4) return;
    setState(() => _pollOptionCtrls.add(TextEditingController()));
  }

  void _removePollOption(int i) {
    if (_pollOptionCtrls.length <= 2) return;
    final ctrl = _pollOptionCtrls.removeAt(i);
    ctrl.dispose();
    setState(() {});
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (date == null) return;
    setState(() => _pollDeadline = date);
  }

  Future<void> _publish() async {
    final text = _contentCtrl.text.trim();
    if (text.isEmpty || _selectedCategoryId == null) return;

    // Validate poll
    if (_addPoll) {
      if (_pollQuestionCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Poll question is required')),
        );
        return;
      }
      final filled = _pollOptionCtrls.where((c) => c.text.trim().isNotEmpty).length;
      if (filled < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('At least 2 poll options are required')),
        );
        return;
      }
    }

    setState(() => _sending = true);
    try {
      // Upload image first if present
      String? imageUrl;
      if (_imageBytes != null && _imageExt != null) {
        final path =
            '${SupabaseService.currentUserId}/${DateTime.now().millisecondsSinceEpoch}.$_imageExt';
        await SupabaseService.uploadPostImage(path, _imageBytes!, _imageExt!);
        imageUrl = SupabaseService.getPostImagePublicUrl(path);
      }

      final postId = await SupabaseService.createPost({
        'content': text,
        'hashtags': _hashtags,
        'is_anonymous': _isAnonymous,
        'category_id': _selectedCategoryId,
        if (imageUrl != null) 'image_url': imageUrl,
      });

      // Create poll if requested
      if (_addPoll) {
        final options = _pollOptionCtrls
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        await SupabaseService.createPoll(
          postId: postId,
          question: _pollQuestionCtrl.text.trim(),
          options: options,
          deadline: _pollDeadline,
        );
      }

      await _clearDraft();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<CategoriesProvider>().categories;
    final auth = context.watch<AuthProvider>();
    final remaining = 2000 - _contentCtrl.text.length;

    _autoSelectCategory(cats);

    final canPublish =
        _contentCtrl.text.trim().isNotEmpty && _selectedCategoryId != null;

    return Scaffold(
      backgroundColor: AppTheme.of(context).surface,
      appBar: AppBar(
        backgroundColor: AppTheme.of(context).surfaceVariant,
        title: const Text('New Post'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            child: _sending
                ? Container(
                    width: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.gradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: canPublish ? _publish : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: canPublish ? AppTheme.gradient : null,
                        color: canPublish ? null : AppTheme.of(context).onSurfaceMuted.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.send_rounded,
                            size: 15,
                            color: canPublish ? Colors.white : AppTheme.of(context).onSurfaceMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Post',
                            style: TextStyle(
                              color: canPublish ? Colors.white : AppTheme.of(context).onSurfaceMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anonymous toggle
            _AnonToggle(
              isAnonymous: _isAnonymous,
              handle: auth.user?.handle ?? 'you',
              onChanged: (v) => setState(() => _isAnonymous = v),
            ),
            const SizedBox(height: 16),

            // Content
            TextField(
              controller: _contentCtrl,
              maxLines: null,
              minLines: 5,
              maxLength: 2000,
              style: const TextStyle(fontSize: 16, height: 1.5),
              decoration: InputDecoration(
                hintText: "What's your take? Use #hashtags.",
                border: InputBorder.none,
                counterStyle: TextStyle(color: AppTheme.of(context).onSurfaceMuted),
              ),
              onChanged: (_) => setState(() {}),
            ),

            // Detected hashtags
            if (_hashtags.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ..._hashtags.map((t) => Chip(
                        label: Text('#$t'),
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                        labelStyle: const TextStyle(color: AppTheme.primary, fontSize: 12),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )),
                ],
              ),
            ],

            // Image picker
            const SizedBox(height: 16),
            Row(
              children: [
                _ActionButton(
                  icon: Icons.image_outlined,
                  label: _imageBytes != null ? 'Change image' : 'Add image',
                  onTap: _pickImage,
                ),
                const SizedBox(width: 10),
                _ActionButton(
                  icon: Icons.poll_outlined,
                  label: _addPoll ? 'Remove poll' : 'Add poll',
                  active: _addPoll,
                  onTap: () => setState(() => _addPoll = !_addPoll),
                ),
              ],
            ),

            // Image preview
            if (_imageBytes != null) ...[
              const SizedBox(height: 12),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _imageBytes!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _imageBytes = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Poll creator
            if (_addPoll) ...[
              const SizedBox(height: 16),
              _PollCreator(
                questionCtrl: _pollQuestionCtrl,
                optionCtrls: _pollOptionCtrls,
                deadline: _pollDeadline,
                onAddOption: _addPollOption,
                onRemoveOption: _removePollOption,
                onPickDeadline: _pickDeadline,
                onClearDeadline: () => setState(() => _pollDeadline = null),
              ),
            ],

            // Category picker (only if multiple)
            if (cats.length > 1) ...[
              const SizedBox(height: 20),
              Text(
                'Category',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.of(context).onSurfaceMuted,
                    fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cats.map((cat) {
                  final sel = _selectedCategoryId == cat.id;
                  return FilterChip(
                    label: Text('${cat.emoji ?? ''} ${cat.name}'),
                    selected: sel,
                    onSelected: (_) => setState(
                        () => _selectedCategoryId = sel ? null : cat.id),
                    selectedColor: AppTheme.primary,
                    checkmarkColor: Colors.white,
                    backgroundColor: AppTheme.of(context).surfaceVariant,
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : AppTheme.of(context).onSurface,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$remaining characters left',
                style: TextStyle(
                  color: remaining < 50 ? Colors.redAccent : AppTheme.of(context).onSurfaceMuted,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _AnonToggle extends StatelessWidget {
  final bool isAnonymous;
  final String handle;
  final void Function(bool) onChanged;

  const _AnonToggle({
    required this.isAnonymous,
    required this.handle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isAnonymous
            ? AppTheme.of(context).onSurfaceMuted.withValues(alpha: 0.1)
            : AppTheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAnonymous
              ? AppTheme.of(context).onSurfaceMuted.withValues(alpha: 0.2)
              : AppTheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAnonymous ? Icons.person_off_outlined : Icons.alternate_email,
            size: 18,
            color: isAnonymous ? AppTheme.of(context).onSurfaceMuted : AppTheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAnonymous ? 'Posting anonymously' : 'Posting as @$handle',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isAnonymous ? AppTheme.of(context).onSurfaceMuted : AppTheme.of(context).onSurface,
                  ),
                ),
                Text(
                  isAnonymous ? 'Your identity is hidden' : 'Your handle will be visible',
                  style: TextStyle(fontSize: 11, color: AppTheme.of(context).onSurfaceMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: isAnonymous,
            onChanged: onChanged,
            activeThumbColor: AppTheme.onSurfaceMuted,
            inactiveThumbColor: AppTheme.primary,
            inactiveTrackColor: AppTheme.primary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.of(context).surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? AppTheme.primary.withValues(alpha: 0.4)
                : AppTheme.of(context).border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: active ? AppTheme.primary : AppTheme.of(context).onSurfaceMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: active ? AppTheme.primary : AppTheme.of(context).onSurfaceMuted,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PollCreator extends StatelessWidget {
  final TextEditingController questionCtrl;
  final List<TextEditingController> optionCtrls;
  final DateTime? deadline;
  final VoidCallback onAddOption;
  final void Function(int) onRemoveOption;
  final VoidCallback onPickDeadline;
  final VoidCallback onClearDeadline;

  const _PollCreator({
    required this.questionCtrl,
    required this.optionCtrls,
    required this.deadline,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onPickDeadline,
    required this.onClearDeadline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.of(context).surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.of(context).border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.poll_outlined, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              const Text('Poll',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: questionCtrl,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Question...',
              counterStyle: TextStyle(color: AppTheme.of(context).onSurfaceMuted, fontSize: 10),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(optionCtrls.length, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: optionCtrls[i],
                        decoration: InputDecoration(hintText: 'Option ${i + 1}'),
                      ),
                    ),
                    if (optionCtrls.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.redAccent, size: 20),
                        onPressed: () => onRemoveOption(i),
                      ),
                  ],
                ),
              )),
          if (optionCtrls.length < 4)
            TextButton.icon(
              onPressed: onAddOption,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add option'),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: AppTheme.of(context).onSurfaceMuted),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onPickDeadline,
                child: Text(
                  deadline != null
                      ? 'Ends ${deadline!.day}/${deadline!.month}/${deadline!.year}'
                      : 'Set deadline (optional)',
                  style: TextStyle(
                    fontSize: 13,
                    color: deadline != null ? AppTheme.primary : AppTheme.onSurfaceMuted,
                  ),
                ),
              ),
              if (deadline != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onClearDeadline,
                  child: Icon(Icons.close, size: 14, color: AppTheme.of(context).onSurfaceMuted),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
