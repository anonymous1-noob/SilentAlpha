import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../common/gradient_button.dart';

class ReportDialog extends StatefulWidget {
  final String? postId;
  final String? commentId;

  const ReportDialog({super.key, this.postId, this.commentId});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selected;
  bool _sending = false;

  static const _reasons = [
    'Spam or misleading',
    'Harassment or bullying',
    'Hate speech',
    'Violence or dangerous content',
    'Sexual content',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.of(context).surfaceVariant,
      title: const Text('Report content'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _reasons.map((r) {
          return GestureDetector(
            onTap: () => setState(() => _selected = r),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    _selected == r
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: _selected == r
                        ? AppTheme.primary
                        : AppTheme.onSurfaceMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(r, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        GradientButton(
          label: 'Submit',
          loading: _sending,
          width: 100,
          onPressed: _selected == null
              ? null
              : () async {
                  setState(() => _sending = true);
                  await SupabaseService.reportContent(
                    postId: widget.postId,
                    commentId: widget.commentId,
                    reason: _selected!,
                  );
                  if (context.mounted) {
                    Navigator.pop(context, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report submitted')),
                    );
                  }
                },
        ),
      ],
    );
  }
}
