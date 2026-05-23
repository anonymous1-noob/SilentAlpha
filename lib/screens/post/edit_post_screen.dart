import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/hashtag_utils.dart';
import '../../utils/ticker_utils.dart';
import '../../widgets/common/gradient_button.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;
  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.post.content);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || text == widget.post.content) return;
    setState(() => _saving = true);
    try {
      await SupabaseService.updatePost(widget.post.id, {
        'content': text,
        'hashtags': HashtagUtils.extractNormalized(text),
        'tickers': TickerUtils.extractNormalized(text),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.of(context).surface,
      appBar: AppBar(
        backgroundColor: AppTheme.of(context).surfaceVariant,
        title: const Text('Edit Post'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GradientButton(
              label: 'Save',
              loading: _saving,
              width: 90,
              onPressed: _save,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _ctrl,
          maxLines: null,
          minLines: 5,
          maxLength: 500,
          style: const TextStyle(fontSize: 16, height: 1.5),
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Edit your post...',
            border: InputBorder.none,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }
}
