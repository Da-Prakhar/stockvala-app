import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/vantage.dart';
import '../repository/notifications_repository.dart';

/// V2 Messages — tabbed inbox with icon rows, red unread dots and
/// "View Detail" links.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = NotificationsRepository.instance;
  List<AppNotification> _items = [];
  bool _loading = true;
  int _tab = 0;

  static const _tabs = ['All', 'Trade', 'Account', 'System'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = _items.isEmpty);
    try {
      final items = await _repo.getNotifications(limit: 50);
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<AppNotification> get _visible {
    if (_tab == 0) return _items;
    final want = _tabs[_tab].toLowerCase();
    return _items.where((n) {
      final t = n.type.toLowerCase();
      if (want == 'trade') return t.contains('trade') || t.contains('position');
      if (want == 'account') {
        return t.contains('account') || t.contains('deposit') ||
            t.contains('withdraw') || t.contains('kyc');
      }
      return t == 'system' || t.isEmpty;
    }).toList();
  }

  String _emoji(String type) {
    final t = type.toLowerCase();
    if (t.contains('deposit') || t.contains('withdraw')) return '👛';
    if (t.contains('trade') || t.contains('position')) return '📈';
    if (t.contains('kyc') || t.contains('account')) return '👤';
    return '📣';
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _open(AppNotification n) async {
    if (!n.isRead) {
      _repo.markRead(n.id).catchError((_) {});
      setState(() {
        _items = _items
            .map((x) => x.id == n.id
                ? AppNotification(id: x.id, title: x.title, body: x.body,
                    type: x.type, isRead: true, createdAt: x.createdAt, data: x.data)
                : x)
            .toList();
      });
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(n.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(_date(n.createdAt),
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            const SizedBox(height: 14),
            Text(n.body,
                style: const TextStyle(fontSize: 14.5, height: 1.45,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 10),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _visible;
    return Scaffold(
      backgroundColor: AppColors.bg100,
      appBar: AppBar(
        backgroundColor: AppColors.bg100,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: const Text('Messages',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Mark all read',
            onPressed: () async {
              await _repo.markAllRead().catchError((_) {});
              _load();
            },
            icon: const Icon(Icons.cleaning_services_rounded, size: 21),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: VTextTabs(
                tabs: _tabs,
                selected: _tab,
                onTap: (i) => setState(() => _tab = i),
              ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.primary))
              : rows.isEmpty
                  ? const Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('📭', style: TextStyle(fontSize: 44)),
                            SizedBox(height: 10),
                            Text('No messages',
                                style: TextStyle(fontSize: 15,
                                    color: AppColors.textMuted)),
                          ]),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.only(top: 6, bottom: 30),
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, indent: 68, color: AppColors.borderLight),
                        itemBuilder: (_, i) {
                          final n = rows[i];
                          return InkWell(
                            onTap: () => _open(n),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 13),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(clipBehavior: Clip.none, children: [
                                      Container(
                                        width: 38, height: 38,
                                        decoration: const BoxDecoration(
                                            color: AppColors.bg300,
                                            shape: BoxShape.circle),
                                        alignment: Alignment.center,
                                        child: Text(_emoji(n.type),
                                            style: const TextStyle(fontSize: 17)),
                                      ),
                                      if (!n.isRead)
                                        Positioned(
                                          top: -1, right: -1,
                                          child: Container(
                                            width: 9, height: 9,
                                            decoration: const BoxDecoration(
                                                color: AppColors.error,
                                                shape: BoxShape.circle),
                                          ),
                                        ),
                                    ]),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(n.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 15.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary)),
                                            const SizedBox(height: 3),
                                            Text(n.body,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 13.5, height: 1.3,
                                                    color: AppColors.textSecondary)),
                                            const SizedBox(height: 6),
                                            Row(children: [
                                              Text(_date(n.createdAt),
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.textMuted)),
                                              const Spacer(),
                                              const Text('View Detail',
                                                  style: TextStyle(fontSize: 12.5,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.primary)),
                                            ]),
                                          ]),
                                    ),
                                  ]),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}
