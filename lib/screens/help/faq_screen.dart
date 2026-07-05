import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const _sections = [
    _Section(
      title: 'Getting Started',
      icon: Icons.rocket_launch_outlined,
      items: [
        _Item(
          q: 'What is TheSilentAlpha?',
          a: 'TheSilentAlpha is a pseudonymous social platform built for finance enthusiasts. '
              'Share market insights, post analysis, rate others\' ideas, and climb the leaderboard — '
              'all with the option to post completely anonymously.',
        ),
        _Item(
          q: 'How do I create an account?',
          a: 'Sign up with your email and choose a unique handle (username). '
              'Your handle is public; your email is never shown to other users.',
        ),
        _Item(
          q: 'Is TheSilentAlpha free?',
          a: 'Yes — TheSilentAlpha is completely free to use.',
        ),
      ],
    ),
    _Section(
      title: 'Posts & Ratings',
      icon: Icons.article_outlined,
      items: [
        _Item(
          q: 'How do I create a post?',
          a: 'Tap the compose button (pencil icon) at the bottom of the feed. '
              'Write your content, optionally add a category, hashtags, or an image, then tap "Post".',
        ),
        _Item(
          q: 'What is the character limit?',
          a: 'Posts can be up to 2,000 characters long.',
        ),
        _Item(
          q: 'How does the rating system work?',
          a: 'Each post has a slider from −5 to +5. Drag it to rate the quality of the insight. '
              'Positive ratings boost the author\'s score; negative ratings reduce it. '
              'The average rating and vote count are shown on every post.',
        ),
        _Item(
          q: 'What is Edge Rank?',
          a: 'Edge Rank is the algorithm that decides post order in the feed. '
              'It weighs average rating, number of ratings, comments, saves, '
              'and how recently the post was made — so fresh, highly-rated posts rise to the top.',
        ),
        _Item(
          q: 'Can I edit or delete my posts?',
          a: 'Yes. Tap the three-dot menu (⋮) on any of your posts to edit or delete it. '
              'Edited posts show an "edited" timestamp.',
        ),
        _Item(
          q: 'What are hashtags?',
          a: 'Add #hashtags to tag topics (e.g. #crypto, #earnings). '
              'Tapping a hashtag opens a filtered feed of related posts.',
        ),
        _Item(
          q: 'What are polls?',
          a: 'You can attach a poll to any post. Add a question, up to 4 options, '
              'and an optional deadline. Readers vote once; results appear after voting.',
        ),
        _Item(
          q: 'What does "Save" do?',
          a: 'Tap the bookmark icon to save a post. Saved posts are private to you '
              'and accessible from your profile under the "Saved" tab.',
        ),
      ],
    ),
    _Section(
      title: 'Anonymous Posts',
      icon: Icons.person_off_outlined,
      items: [
        _Item(
          q: 'How does anonymous posting work?',
          a: 'Toggle the anonymous switch before posting. Your post will appear under '
              '"@anonymous" with no avatar or handle — other users cannot identify you as the author.',
        ),
        _Item(
          q: 'Can I see my own anonymous posts?',
          a: 'Yes. On your own posts you always see the real author, even in anonymous mode. '
              'Others only see "@anonymous".',
        ),
        _Item(
          q: 'Do anonymous posts count toward my score?',
          a: 'Yes. Ratings on your anonymous posts still add to your total score and leaderboard rank, '
              'even though other users cannot link those posts to you.',
        ),
        _Item(
          q: 'Will anonymous posts appear on my profile?',
          a: 'No. Anonymous posts are hidden from your public profile so visitors cannot identify them.',
        ),
      ],
    ),
    _Section(
      title: 'Leaderboard & Badges',
      icon: Icons.leaderboard_outlined,
      items: [
        _Item(
          q: 'What is the leaderboard?',
          a: 'The leaderboard ranks all users by their total post-rating score. '
              'The top 50 users are shown. It refreshes once per day.',
        ),
        _Item(
          q: 'What are the medal icons on avatars?',
          a: '🥇 Gold, 🥈 Silver, and 🥉 Bronze medals appear on the avatars of the '
              'top 3 users on the leaderboard. They show on both posts in the feed and on profiles.',
        ),
        _Item(
          q: 'What are the badges?',
          a: 'Badges reflect your cumulative score tier:\n\n'
              '📄 Paper Trader — score < 0\n'
              '👀 Market Lurker — 0–20\n'
              '🐂 Bull Rider — 21–75\n'
              '🔍 Analyst — 76–200\n'
              '💼 Portfolio Pro — 201–500\n'
              '⚡ Quant — 501–1500\n'
              '🐺 Wolf of the Street — 1501+',
        ),
        _Item(
          q: 'How do I improve my score?',
          a: 'Post high-quality insights that others rate positively. '
              'Consistent +3 to +5 ratings on your posts will grow your score quickly.',
        ),
      ],
    ),
    _Section(
      title: 'Following & Privacy',
      icon: Icons.people_outline,
      items: [
        _Item(
          q: 'How do I follow someone?',
          a: 'Visit their profile and tap "Follow". If their account is private, '
              'they must approve your request before you can see their following feed.',
        ),
        _Item(
          q: 'What is the Following feed?',
          a: 'The "Following" tab in the feed shows only posts from people you follow, '
              'ordered by Edge Rank.',
        ),
        _Item(
          q: 'How do I accept or decline a follow request?',
          a: 'Open the Activity screen (bell icon). Follow requests appear with '
              'Accept and Decline buttons. Once actioned, the request is removed.',
        ),
        _Item(
          q: 'Can I block a user?',
          a: 'Yes. Visit the user\'s profile, tap the three-dot menu in the top-right corner, '
              'and select "Block user". They will no longer be able to interact with you.',
        ),
      ],
    ),
    _Section(
      title: 'Profile & Account',
      icon: Icons.manage_accounts_outlined,
      items: [
        _Item(
          q: 'How do I edit my profile?',
          a: 'Go to your profile and tap the settings icon (⚙). '
              'You can update your handle, bio, tagline, and profile picture.',
        ),
        _Item(
          q: 'What is the profile picture size limit?',
          a: 'Profile pictures are automatically compressed to ≤ 100 KB at up to 512×512 px '
              'before uploading, so you don\'t need to resize them manually.',
        ),
        _Item(
          q: 'How do I switch between light and dark mode?',
          a: 'Go to your profile and tap the sun/moon icon in the top-right corner '
              'to toggle between light and dark theme.',
        ),
        _Item(
          q: 'What is the tagline?',
          a: 'A short line (shown under your handle on your profile) to describe '
              'your trading style or philosophy — e.g. "Long-term value investor".',
        ),
      ],
    ),
  ];

  List<_Section> get _filtered {
    if (_query.isEmpty) return _sections;
    final q = _query.toLowerCase();
    return _sections
        .map((s) => _Section(
              title: s.title,
              icon: s.icon,
              items: s.items
                  .where((i) =>
                      i.q.toLowerCase().contains(q) ||
                      i.a.toLowerCase().contains(q))
                  .toList(),
            ))
        .where((s) => s.items.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppTheme.of(context).surface,
      appBar: AppBar(
        backgroundColor: AppTheme.of(context).surfaceVariant,
        title: ShaderMask(
          shaderCallback: (b) => AppTheme.gradient.createShader(b),
          child: const Text(
            'Help & FAQ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(color: AppTheme.of(context).onSurface),
              decoration: InputDecoration(
                hintText: 'Search questions…',
                hintStyle: TextStyle(color: AppTheme.of(context).onSurfaceMuted),
                prefixIcon: Icon(Icons.search, color: AppTheme.of(context).onSurfaceMuted),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppTheme.of(context).onSurfaceMuted),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.of(context).surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No results for "$_query"',
                      style: TextStyle(color: AppTheme.of(context).onSurfaceMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: filtered.length,
                    itemBuilder: (_, si) {
                      final section = filtered[si];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
                            child: Row(
                              children: [
                                ShaderMask(
                                  shaderCallback: (b) =>
                                      AppTheme.gradient.createShader(b),
                                  child: Icon(section.icon,
                                      size: 18, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                ShaderMask(
                                  shaderCallback: (b) =>
                                      AppTheme.gradient.createShader(b),
                                  child: Text(
                                    section.title.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.of(context).cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.of(context).border),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Column(
                                children: [
                                  for (int i = 0; i < section.items.length; i++) ...[
                                    _FaqTile(
                                      item: section.items[i],
                                      query: _query,
                                    ),
                                    if (i < section.items.length - 1)
                                      Divider(
                                          height: 1,
                                          color: AppTheme.of(context).border),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final _Item item;
  final String query;

  const _FaqTile({required this.item, required this.query});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: AppTheme.primary,
        collapsedIconColor: AppTheme.of(context).onSurfaceMuted,
        title: _HighlightText(
          text: item.q,
          query: query,
          style: TextStyle(
            color: AppTheme.of(context).onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          highlightColor: AppTheme.primary,
        ),
        children: [
          _HighlightText(
            text: item.a,
            query: query,
            style: TextStyle(
              color: AppTheme.of(context).onSurfaceMuted,
              fontSize: 13,
              height: 1.55,
            ),
            highlightColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final Color highlightColor;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.style,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: style);

    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: style));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + q.length),
        style: style.copyWith(
          color: highlightColor,
          fontWeight: FontWeight.w800,
          backgroundColor: highlightColor.withValues(alpha: 0.12),
        ),
      ));
      start = idx + q.length;
    }

    return RichText(text: TextSpan(children: spans));
  }
}

class _Section {
  final String title;
  final IconData icon;
  final List<_Item> items;

  const _Section({
    required this.title,
    required this.icon,
    required this.items,
  });
}

class _Item {
  final String q;
  final String a;

  const _Item({required this.q, required this.a});
}
