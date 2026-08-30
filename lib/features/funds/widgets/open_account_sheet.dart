import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/mt5_account_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/vantage.dart';

/// "Open Trading Account" — account type + leverage chips, orange CTA.
/// On success shows the one-time MT5 credentials with copy actions.
Future<void> showOpenAccountSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _OpenAccountSheet(),
  );
}

class _OpenAccountSheet extends StatefulWidget {
  const _OpenAccountSheet();
  @override
  State<_OpenAccountSheet> createState() => _OpenAccountSheetState();
}

class _OpenAccountSheetState extends State<_OpenAccountSheet> {
  String _type = 'live';
  int _leverage = 1000;
  bool _busy = false;

  static const _leverages = [100, 200, 500, 1000, 2000, 5000];

  Future<void> _create() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final acc = await Mt5AccountStore.instance.createAccount(
        accountType: _type,
        leverage: _leverage,
      );
      if (!mounted) return;
      Navigator.pop(context);
      // One-time credentials — show them clearly with copy buttons.
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Account Created',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            _CredRow('Login', acc.login),
            if (acc.tradingPassword != null)
              _CredRow('Password', acc.tradingPassword!),
            if (acc.investorPassword != null)
              _CredRow('Investor', acc.investorPassword!),
            _CredRow('Server', acc.server),
            const SizedBox(height: 8),
            const Text('Save these credentials — the password is shown only once.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is ApiException ? e.message : 'Could not open account'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.bg400,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Open Trading Account',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Your MT5 account is created instantly and ready to fund.',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
          const SizedBox(height: 22),
          const Text('Account Type',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Row(children: [
            _TypeChip(
              label: 'Live', sub: 'Real funds',
              selected: _type == 'live',
              onTap: () => setState(() => _type = 'live'),
            ),
            const SizedBox(width: 10),
            _TypeChip(
              label: 'Demo', sub: 'Practice',
              selected: _type == 'demo',
              onTap: () => setState(() => _type = 'demo'),
            ),
          ]),
          const SizedBox(height: 20),
          const Text('Leverage',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final l in _leverages)
              GestureDetector(
                onTap: () => setState(() => _leverage = l),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: _leverage == l
                        ? AppColors.primaryLighter : AppColors.bg300,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: _leverage == l
                            ? AppColors.primary : Colors.transparent),
                  ),
                  child: Text('1:$l',
                      style: TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _leverage == l
                              ? AppColors.primary : AppColors.textSecondary)),
                ),
              ),
          ]),
          const SizedBox(height: 24),
          VPill(label: 'Open Account', loading: _busy, onPressed: _create),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label, sub;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.sub,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryLighter : AppColors.bg300,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: selected ? AppColors.primary : Colors.transparent,
                  width: 1.4),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                      color: selected
                          ? AppColors.primary : AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(fontSize: 12,
                  color: AppColors.textMuted)),
            ]),
          ),
        ),
      );
}

class _CredRow extends StatelessWidget {
  final String label, value;
  const _CredRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          SizedBox(width: 74,
              child: Text(label,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted))),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('$label copied'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textMuted),
          ),
        ]),
      );
}
