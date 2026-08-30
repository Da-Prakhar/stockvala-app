import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/vantage.dart';
import '../repository/wallet_verification_repository.dart';

/// Payout wallet verification — matches the v7 flow:
/// up to 3 addresses, each with a wallet video; rejections are strikes;
/// 3 strikes lock the balance until an identity video is approved.
class WalletVerificationScreen extends StatefulWidget {
  const WalletVerificationScreen({super.key});
  @override
  State<WalletVerificationScreen> createState() => _WalletVerificationScreenState();
}

class _WalletVerificationScreenState extends State<WalletVerificationScreen> {
  final _repo = WalletVerificationRepository.instance;
  WalletVerificationState? _state;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = _state == null; _error = null; });
    try {
      final s = await _repo.getState();
      if (mounted) setState(() { _state = s; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is ApiException ? e.message : e.toString();
        });
      }
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _addAddress() async {
    final s = _state;
    if (s == null) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddAddressSheet(accountName: s.accountName),
    );
    if (result == true) {
      _snack('Wallet submitted for verification');
      _load();
    }
  }

  Future<void> _remove(WalletAddressEntry a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove this wallet?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Text('${a.shortAddress}\nA rejected wallet still counts toward your strikes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.removeAddress(a.id);
      _snack('Wallet removed');
      _load();
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Could not remove wallet', error: true);
    }
  }

  Future<void> _requestUnlock() async {
    final s = _state;
    if (s == null) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _UnlockSheet(accountName: s.accountName),
    );
    if (result == true) {
      _snack('Identity video submitted — the broker will review it');
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _state;
    return Scaffold(
      backgroundColor: AppColors.bg100,
      appBar: AppBar(
        backgroundColor: AppColors.bg100,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: const Text('Payout Wallets',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.headset_mic_rounded, size: 23),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              strokeWidth: 2.5, color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_error!, style: const TextStyle(color: AppColors.textMuted)),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                    children: [
                      // ── Lock banner ─────────────────────────────────────
                      if (s!.locked) ...[
                        VCard(
                          color: AppColors.errorBg,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(children: [
                                  Text('🔒', style: TextStyle(fontSize: 22)),
                                  SizedBox(width: 8),
                                  Text('Balance locked',
                                      style: TextStyle(fontSize: 16.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.error)),
                                ]),
                                const SizedBox(height: 6),
                                Text(
                                  '${s.lock!['reason'] ?? 'Too many failed wallet verifications.'}\n'
                                  'Unlocks in ${s.lock!['daysRemaining'] ?? '—'} days, or submit '
                                  'an identity video for early review.',
                                  style: const TextStyle(fontSize: 13.5, height: 1.35,
                                      color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 12),
                                if (s.unlockRequest != null &&
                                    (s.unlockRequest!['status'] == 'pending'))
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.warningBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text('Identity video under review',
                                        style: TextStyle(fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.warning)),
                                  )
                                else
                                  VPill(label: 'Submit Identity Video', dark: true,
                                      onPressed: _requestUnlock),
                              ]),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── Strikes / limits ───────────────────────────────
                      VCard(
                        child: Row(children: [
                          _Stat('${s.used}/${s.max}', 'Wallets'),
                          _divider(),
                          _Stat('${s.strikes}', 'Strikes',
                              color: s.strikes > 0 ? AppColors.error : null),
                          _divider(),
                          _Stat('${s.strikesRemaining}', 'Attempts Left'),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      const VSectionHeader('Verified Payout Addresses'),
                      const SizedBox(height: 4),
                      const Text(
                        'Withdrawals are only sent to wallets in your own name, '
                        'verified with a short wallet video.',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.3),
                      ),
                      const SizedBox(height: 12),

                      if (s.addresses.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 34),
                          child: Center(
                            child: Column(children: [
                              Text('👛', style: TextStyle(fontSize: 42)),
                              SizedBox(height: 10),
                              Text('No payout wallets yet',
                                  style: TextStyle(fontSize: 15,
                                      color: AppColors.textMuted)),
                            ]),
                          ),
                        )
                      else
                        ...s.addresses.map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AddressCard(entry: a, onRemove: () => _remove(a)),
                            )),

                      const SizedBox(height: 10),
                      if (!s.locked && s.remaining > 0)
                        VPill(label: 'Add Wallet Address', onPressed: _addAddress)
                      else if (!s.locked)
                        const Center(
                          child: Text('Address limit reached — remove one to add another',
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _divider() => Container(width: 1, height: 30, color: AppColors.border);
}

class _Stat extends StatelessWidget {
  final String v, l;
  final Color? color;
  const _Stat(this.v, this.l, {this.color});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(v, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800,
              color: color ?? AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(l, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ]),
      );
}

class _AddressCard extends StatelessWidget {
  final WalletAddressEntry entry;
  final VoidCallback onRemove;
  const _AddressCard({required this.entry, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final (chipBg, chipFg, chipLabel) = switch (entry.status) {
      'verified' => (AppColors.successBg, AppColors.success, 'Verified'),
      'rejected' => (AppColors.errorBg, AppColors.error, 'Rejected'),
      _ => (AppColors.warningBg, AppColors.warning, 'Pending'),
    };
    return VCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(entry.currency == 'USDT' ? '💵' : '🪙',
                style: const TextStyle(fontSize: 19)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('${entry.currency} · ${entry.network}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                if (entry.label != null && entry.label!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text('(${entry.label})',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                ],
              ]),
              const SizedBox(height: 2),
              Text(entry.shortAddress,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(9)),
            child: Text(chipLabel,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: chipFg)),
          ),
        ]),
        if (entry.status == 'rejected' && entry.adminNote != null) ...[
          const SizedBox(height: 8),
          Text('Reason: ${entry.adminNote}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.error)),
        ],
        if (entry.status != 'verified') ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onRemove,
            child: const Text('Remove',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.underline)),
          ),
        ],
      ]),
    );
  }
}

// ── Add-address sheet ────────────────────────────────────────────────────────
class _AddAddressSheet extends StatefulWidget {
  final String accountName;
  const _AddAddressSheet({required this.accountName});
  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  final _addressCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  late final _nameCtrl = TextEditingController(text: widget.accountName);
  String _network = 'TRC20';
  XFile? _video;
  bool _submitting = false;
  String? _error;

  static const _networks = ['TRC20', 'ERC20', 'BEP20'];

  Future<void> _pickVideo() async {
    try {
      final v = await ImagePicker().pickVideo(source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 2));
      if (v != null && mounted) setState(() => _video = v);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open the video picker');
    }
  }

  Future<void> _submit() async {
    final addr = _addressCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    if (addr.length < 12) {
      setState(() => _error = 'Enter a valid wallet address');
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = 'Enter the name on the wallet');
      return;
    }
    if (_video == null) {
      setState(() => _error = 'Attach a short video of the wallet showing your name and this address');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      await WalletVerificationRepository.instance.addAddress(
        network: _network,
        currency: 'USDT',
        address: addr,
        holderName: name,
        label: _labelCtrl.text.trim(),
        proofVideoPath: _video!.path,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e is ApiException ? e.message : 'Submission failed';
        });
      }
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
        filled: true,
        fillColor: AppColors.bg300,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add Payout Wallet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('USDT only. The wallet must be in your own name.',
              style: TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
          const SizedBox(height: 18),

          Row(children: [
            for (final n in _networks)
              GestureDetector(
                onTap: () => setState(() => _network = n),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _network == n ? AppColors.primaryLighter : AppColors.bg300,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _network == n ? AppColors.primary : Colors.transparent),
                  ),
                  child: Text(n,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700,
                          color: _network == n
                              ? AppColors.primary : AppColors.textSecondary)),
                ),
              ),
          ]),
          const SizedBox(height: 14),
          TextField(controller: _addressCtrl, decoration: _dec('Wallet address'),
              style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 10),
          TextField(controller: _nameCtrl, decoration: _dec('Name on the wallet'),
              style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 10),
          TextField(controller: _labelCtrl, decoration: _dec('Label (optional)'),
              style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 14),

          GestureDetector(
            onTap: _pickVideo,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _video != null ? AppColors.successBg : AppColors.bg300,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _video != null ? AppColors.success : AppColors.border),
              ),
              child: Row(children: [
                Icon(_video != null ? Icons.check_circle_rounded : Icons.videocam_rounded,
                    color: _video != null ? AppColors.success : AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _video != null
                        ? 'Wallet video attached'
                        : 'Attach wallet video (name + address visible)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: _video != null
                            ? AppColors.success : AppColors.textSecondary),
                  ),
                ),
              ]),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.error)),
          ],
          const SizedBox(height: 18),
          VPill(label: 'Submit for Verification', loading: _submitting,
              onPressed: _submitting ? null : _submit),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ── Unlock-request sheet ─────────────────────────────────────────────────────
class _UnlockSheet extends StatefulWidget {
  final String accountName;
  const _UnlockSheet({required this.accountName});
  @override
  State<_UnlockSheet> createState() => _UnlockSheetState();
}

class _UnlockSheetState extends State<_UnlockSheet> {
  late final _nameCtrl = TextEditingController(text: widget.accountName);
  final _addrCtrl = TextEditingController();
  XFile? _video;
  bool _submitting = false;
  String? _error;

  Future<void> _pickVideo() async {
    try {
      final v = await ImagePicker().pickVideo(source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
          maxDuration: const Duration(minutes: 2));
      if (v != null && mounted) setState(() => _video = v);
    } catch (_) {
      final v = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (v != null && mounted) setState(() => _video = v);
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter the name exactly as on your wallet');
      return;
    }
    if (_video == null) {
      setState(() => _error = 'Attach the identity video');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      await WalletVerificationRepository.instance.requestUnlock(
        declaredName: _nameCtrl.text.trim(),
        walletAddress: _addrCtrl.text.trim(),
        videoPath: _video!.path,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e is ApiException ? e.message : 'Submission failed';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Identity Verification',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text(
            'Record yourself holding the crypto wallet: your face, the name '
            'on the wallet and its address must all be visible.',
            style: TextStyle(fontSize: 13.5, height: 1.35, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: 'Name on the wallet',
              filled: true, fillColor: AppColors.bg300,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _addrCtrl,
            decoration: InputDecoration(
              hintText: 'Wallet address shown in the video (optional)',
              filled: true, fillColor: AppColors.bg300,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _pickVideo,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _video != null ? AppColors.successBg : AppColors.bg300,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _video != null ? AppColors.success : AppColors.border),
              ),
              child: Row(children: [
                Icon(_video != null ? Icons.check_circle_rounded : Icons.videocam_rounded,
                    color: _video != null ? AppColors.success : AppColors.textSecondary),
                const SizedBox(width: 10),
                Text(_video != null ? 'Identity video attached' : 'Record identity video',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: _video != null
                            ? AppColors.success : AppColors.textSecondary)),
              ]),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.error)),
          ],
          const SizedBox(height: 18),
          VPill(label: 'Submit for Review', dark: true, loading: _submitting,
              onPressed: _submitting ? null : _submit),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
