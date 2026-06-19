import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../repository/notifications_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await NotificationsRepository.instance.getNotifications();
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _markAllRead() async {
    await NotificationsRepository.instance.markAllRead();
    setState(() {
      _items = _items.map((n) => AppNotification(
        id: n.id, title: n.title, body: n.body, type: n.type,
        isRead: true, createdAt: n.createdAt, data: n.data,
      )).toList();
    });
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;
    await NotificationsRepository.instance.markRead(n.id);
    final idx = _items.indexWhere((x) => x.id == n.id);
    if (idx >= 0 && mounted) {
      setState(() {
        _items[idx] = AppNotification(
          id: n.id, title: n.title, body: n.body, type: n.type,
          isRead: true, createdAt: n.createdAt, data: n.data,
        );
      });
    }
  }

  static IconData _iconFor(String type) => switch (type) {
    'trade' => Icons.trending_up_rounded,
    'deposit' || 'withdrawal' => Icons.attach_money_rounded,
    'kyc' => Icons.verified_user_rounded,
    'margin' => Icons.warning_amber_rounded,
    'copy_trading' => Icons.people_alt_rounded,
    'pamm' => Icons.account_balance_rounded,
    _ => Icons.notifications_rounded,
  };

  static Color _colorFor(String type) => switch (type) {
    'trade' => AppColors.bullish,
    'deposit' => AppColors.success,
    'withdrawal' => AppColors.accent,
    'kyc' => AppColors.primary,
    'margin' => AppColors.error,
    'copy_trading' => AppColors.primary,
    'pamm' => AppColors.gold,
    _ => AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg100,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications'),
        actions: [
          if (_items.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllRead,
              child: Text('Mark all read', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_rounded, color: AppColors.textMuted, size: 48),
      const SizedBox(height: 12),
      const Text('Could not load notifications', style: AppTextStyles.bodyMedium),
      const SizedBox(height: 8),
      TextButton(onPressed: _load, child: const Text('Retry')),
    ]));
    if (_items.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: AppColors.primaryLighter, shape: BoxShape.circle),
          child: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 48)),
      const SizedBox(height: 16),
      const Text('No notifications', style: AppTextStyles.headingSmall),
      const SizedBox(height: 8),
      const Text('You\'re all caught up!', style: AppTextStyles.bodySmall),
    ]));

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final item = _items[i];
        return GestureDetector(
          onTap: () => _markRead(item),
          child: _NotifTile(
            icon: _iconFor(item.type),
            color: _colorFor(item.type),
            title: item.title,
            body: item.body,
            time: _relativeTime(item.createdAt),
            unread: !item.isRead,
          ).animate(delay: (i * 40).ms).fadeIn().slideX(begin: 0.05, end: 0),
        );
      },
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, body, time;
  final bool unread;
  const _NotifTile({required this.icon, required this.color, required this.title, required this.body, required this.time, required this.unread});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: unread ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: AppTextStyles.labelMedium.copyWith(
          color: unread ? AppColors.textPrimary : AppColors.textSecondary,
        )),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 2),
          Text(body, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(time, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        ]),
        trailing: unread
            ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))
            : null,
      ),
    );
  }
}
