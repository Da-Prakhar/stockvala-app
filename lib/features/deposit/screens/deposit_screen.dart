import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/mt5_account_store.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/app_button.dart';
import '../../finance/repository/finance_repository.dart';

class DepositScreen extends StatefulWidget {
  final bool isWithdraw;
  const DepositScreen({super.key, this.isWithdraw = false});
  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  // ── Account selector ────────────────────────────────────────────────────────
  Mt5Account? _selectedAccount;

  // ── Payment methods (from API) ───────────────────────────────────────────────
  List<PaymentMethod> _methods = [];
  PaymentMethod? _selectedMethod;
  bool _loadingMethods = true;
  String? _methodsError;

  // ── Form ─────────────────────────────────────────────────────────────────────
  final _amtCtrl = TextEditingController();
  bool _submitting = false;
  String? _errorMsg;
  final List<double> _quick = [100, 250, 500, 1000, 2500, 5000];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedAccount ??= Mt5AccountStore.instance.active;
  }

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _amtCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() { _loadingMethods = true; _methodsError = null; });
    try {
      final methods = await FinanceRepository.instance.getPaymentMethods();
      if (mounted) {
        setState(() {
          _methods = methods;
          _loadingMethods = false;
          // Auto-select first method
          if (methods.isNotEmpty) _selectedMethod = methods.first;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingMethods = false;
          _methodsError = 'Could not load payment methods. Tap to retry.';
        });
      }
    }
  }

  void _pickAccount(BuildContext context, List<Mt5Account> accounts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AccountPickerSheet(
        accounts: accounts,
        selected: _selectedAccount,
        onSelect: (acc) => setState(() { _selectedAccount = acc; _errorMsg = null; }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isW = widget.isWithdraw;
    return Consumer<Mt5AccountStore>(
      builder: (_, store, __) {
        _selectedAccount ??= store.active;
        final acc = _selectedAccount;
        final balance = acc?.balance ?? 0.0;

        return Scaffold(
          backgroundColor: AppColors.bg100,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(isW ? 'Withdraw Funds' : 'Deposit Funds'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Balance card + account selector ──────────────────────────────
              _buildBalanceCard(context, store, acc, balance, isW),

              const SizedBox(height: 20),

              // ── Error banner ─────────────────────────────────────────────────
              if (_errorMsg != null) _buildErrorBanner(),

              // ── Amount input ─────────────────────────────────────────────────
              Text('Enter Amount', style: AppTextStyles.headingSmall)
                  .animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 10),
              _buildAmountInput(acc, isW),

              const SizedBox(height: 12),

              // ── Quick amounts ─────────────────────────────────────────────────
              _buildQuickAmounts(),

              const SizedBox(height: 24),

              // ── Payment methods ───────────────────────────────────────────────
              Text(isW ? 'Withdrawal Method' : 'Payment Method',
                  style: AppTextStyles.headingSmall)
                  .animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),

              _buildPaymentMethods(),

              // ── Selected method details ───────────────────────────────────────
              if (_selectedMethod != null && !isW) ...[
                const SizedBox(height: 12),
                _buildMethodDetails(_selectedMethod!),
              ],

              const SizedBox(height: 16),

              _buildSecurityBadge(),

              const SizedBox(height: 20),

              AppButton(
                label: isW ? 'Request Withdrawal' : 'Submit Deposit',
                isLoading: _submitting,
                onPressed: (_selectedMethod != null &&
                    _amtCtrl.text.isNotEmpty &&
                    !_submitting &&
                    acc != null)
                    ? () => _proceed(acc, balance, isW)
                    : null,
                suffixIcon: Icons.arrow_forward_rounded,
              ).animate().fadeIn(delay: 550.ms),

              const SizedBox(height: 24),
            ]),
          ),
        );
      },
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────────

  Widget _buildBalanceCard(BuildContext context, Mt5AccountStore store,
      Mt5Account? acc, double balance, bool isW) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Available Balance',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            acc == null
                ? const Text('No account linked',
                style: TextStyle(color: Colors.white54, fontSize: 22, fontWeight: FontWeight.w700))
                : Text('\$${balance.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 28,
                    fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          ])),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(isW ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: Colors.white, size: 26),
          ),
        ]),

        const SizedBox(height: 14),

        // Account selector
        GestureDetector(
          onTap: () => _pickAccount(context, store.accounts),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Expanded(child: acc == null
                  ? const Text('Tap to select an MT5 account',
                  style: TextStyle(color: Colors.white60, fontSize: 12))
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('MT5 Account #${acc.login}',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 13, fontWeight: FontWeight.w800)),
                Text('${acc.server}  ·  ${acc.type}  ·  ${acc.isReal ? 'REAL' : 'DEMO'}',
                    style: const TextStyle(color: Colors.white60, fontSize: 10)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.swap_vert_rounded, color: Colors.white, size: 12),
                  const SizedBox(width: 3),
                  Text(
                    store.accounts.length > 1 ? 'Switch (${store.accounts.length})' : 'Select',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildErrorBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(_errorMsg!,
              style: const TextStyle(color: AppColors.error, fontSize: 13))),
          GestureDetector(
            onTap: () => setState(() => _errorMsg = null),
            child: const Icon(Icons.close, color: AppColors.error, size: 18),
          ),
        ]),
      ),
    );
  }

  Widget _buildAmountInput(Mt5Account? acc, bool isW) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bg200,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Row(children: [
        const Text('USD',
            style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(width: 14),
        Container(width: 1, height: 26, color: AppColors.border),
        const SizedBox(width: 14),
        Expanded(child: TextField(
          controller: _amtCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTextStyles.numericMedium,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
              border: InputBorder.none, hintText: '0.00', isDense: true),
        )),
        if (isW && acc != null)
          GestureDetector(
            onTap: () => setState(() => _amtCtrl.text = acc.balance.toStringAsFixed(2)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.primaryLighter, borderRadius: BorderRadius.circular(6)),
              child: const Text('MAX',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ),
          ),
      ]),
    ).animate().fadeIn(delay: 120.ms);
  }

  Widget _buildQuickAmounts() {
    // Use minAmount from selected method if available
    final min = _selectedMethod?.minAmount ?? 10;
    final amounts = _quick.where((a) => a >= min).toList();
    if (amounts.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8, runSpacing: 8,
      children: amounts.map((a) => GestureDetector(
        onTap: () => setState(() => _amtCtrl.text = a.toInt().toString()),
        child: AnimatedContainer(
          duration: 150.ms,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _amtCtrl.text == a.toInt().toString()
                ? AppColors.primaryLighter : AppColors.bg200,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: _amtCtrl.text == a.toInt().toString()
                    ? AppColors.primary : AppColors.border),
          ),
          child: Text('\$${a.toInt()}',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _amtCtrl.text == a.toInt().toString()
                      ? AppColors.primary : AppColors.textMuted)),
        ),
      )).toList(),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildPaymentMethods() {
    if (_loadingMethods) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(color: AppColors.primary),
      ));
    }

    if (_methodsError != null) {
      return GestureDetector(
        onTap: _loadPaymentMethods,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.errorBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.refresh_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(_methodsError!,
                style: const TextStyle(color: AppColors.error, fontSize: 13))),
          ]),
        ),
      );
    }

    if (_methods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bg200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(children: [
          Icon(Icons.payment_outlined, color: AppColors.textMuted, size: 32),
          SizedBox(height: 8),
          Text('No payment methods available.\nPlease contact support.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ]),
      );
    }

    return Column(
      children: _methods.asMap().entries.map((e) {
        final m = e.value;
        final isSelected = _selectedMethod?.id == m.id;
        final color = _colorForType(m.type);
        final icon = _iconForType(m.type);

        return GestureDetector(
          onTap: () => setState(() { _selectedMethod = m; _errorMsg = null; }),
          child: AnimatedContainer(
            duration: 200.ms,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.06) : AppColors.bg100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: isSelected ? 1.5 : 1),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.name, style: AppTextStyles.labelLarge),
                const SizedBox(height: 3),
                Row(children: [
                  if (m.network != null) ...[
                    const Icon(Icons.cable_rounded, color: AppColors.textMuted, size: 11),
                    Text(' ${m.network}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    const Text('  ·  ', style: TextStyle(color: AppColors.textMuted)),
                  ],
                  Text('Min: \$${m.minAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                ]),
              ])),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
            ]),
          ).animate().fadeIn(delay: Duration(milliseconds: 250 + e.key * 50)),
        );
      }).toList(),
    );
  }

  Widget _buildMethodDetails(PaymentMethod m) {
    // Show wallet address / bank details so user knows where to send
    if (m.walletAddress == null && m.bankName == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg200,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 16),
          SizedBox(width: 8),
          Text('Payment Instructions',
              style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),

        if (m.walletAddress != null) ...[
          const Text('Send to wallet address:',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: m.walletAddress!));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Wallet address copied!'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bg300,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                Expanded(child: Text(m.walletAddress!,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12,
                        color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                const SizedBox(width: 8),
                const Icon(Icons.copy_rounded, color: AppColors.primary, size: 16),
              ]),
            ),
          ),
          if (m.network != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: AppColors.warningBg, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 14),
                const SizedBox(width: 6),
                Text('Network: ${m.network} only',
                    style: const TextStyle(color: AppColors.warning, fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ],

        if (m.bankName != null) ...[
          _DetailRow('Bank', m.bankName!),
          if (m.accountNumber != null) _DetailRow('Account', m.accountNumber!),
          if (m.ifsc != null) _DetailRow('IFSC', m.ifsc!),
        ],

        const SizedBox(height: 10),
        const Text(
          'After making payment, submit this form. Our team will verify and credit your account within 30 minutes.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ]),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: const Row(children: [
        Icon(Icons.verified_user_outlined, color: AppColors.success, size: 20),
        SizedBox(width: 10),
        Expanded(child: Text('256-bit SSL encrypted. Your funds are secure.',
            style: TextStyle(color: AppColors.success, fontSize: 12))),
      ]),
    ).animate().fadeIn(delay: 500.ms);
  }

  // ── Submit ────────────────────────────────────────────────────────────────────

  Future<void> _proceed(Mt5Account acc, double balance, bool isW) async {
    final amount = double.tryParse(_amtCtrl.text);
    if (amount == null || amount <= 0) {
      setState(() => _errorMsg = 'Please enter a valid amount');
      return;
    }

    final method = _selectedMethod!;
    final minAmt = method.minAmount > 0 ? method.minAmount : 10;
    if (amount < minAmt) {
      setState(() => _errorMsg =
      'Minimum ${isW ? 'withdrawal' : 'deposit'} is \$${minAmt.toStringAsFixed(0)} for ${method.name}');
      return;
    }
    if (method.maxAmount > 0 && amount > method.maxAmount) {
      setState(() => _errorMsg =
      'Maximum ${isW ? 'withdrawal' : 'deposit'} is \$${method.maxAmount.toStringAsFixed(0)} for ${method.name}');
      return;
    }
    if (isW && amount > balance) {
      setState(() => _errorMsg =
      'Withdrawal amount exceeds balance (\$${balance.toStringAsFixed(2)}) on account #${acc.login}');
      return;
    }
    if (int.tryParse(acc.id) == null) {
      setState(() => _errorMsg =
      'This is a demo/seed account. Please link a real MT5 account to make transactions.');
      return;
    }

    setState(() { _submitting = true; _errorMsg = null; });

    try {
      FinanceTransaction tx;
      if (isW) {
        try {
          tx = await FinanceRepository.instance.withdraw(
            accountId: acc.id,
            amount: amount,
            paymentMethodId: method.id,
          );
        } on ApiException catch (e) {
          // Broker requires an email OTP for withdrawals — fetch one and ask.
          if (!e.message.toLowerCase().contains('otp is required')) rethrow;
          await FinanceRepository.instance.requestWithdrawalOtp();
          if (!mounted) return;
          final code = await _promptWithdrawalOtp();
          if (code == null || code.isEmpty) {
            setState(() { _submitting = false; _errorMsg = 'Withdrawal cancelled — OTP not entered'; });
            return;
          }
          tx = await FinanceRepository.instance.withdraw(
            accountId: acc.id,
            amount: amount,
            paymentMethodId: method.id,
            otp: code,
          );
        }
      } else {
        tx = await FinanceRepository.instance.deposit(
          accountId: acc.id,
          amount: amount,
          paymentMethodId: method.id,
        );
      }

      if (!mounted) return;
      Mt5AccountStore.instance.loadAccounts();

      final nav = Navigator.of(context);
      nav.pop();

      // Show success with transaction ID
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              '${isW ? 'Withdrawal' : 'Deposit'} submitted — \$${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ]),
          const SizedBox(height: 4),
          Text('Ref: #${tx.id} · Status: ${tx.status}',
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.userMessage : e.toString();
      setState(() { _submitting = false; _errorMsg = msg; });
    }
  }

  /// Modal asking for the withdrawal OTP that was just emailed.
  Future<String?> _promptWithdrawalOtp() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Withdrawal Verification',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('We emailed you a one-time code. Enter it to confirm this withdrawal.',
              style: TextStyle(fontSize: 13)),
          const SizedBox(height: 14),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 8),
            decoration: const InputDecoration(counterText: '', hintText: '••••••'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Color _colorForType(String type) => switch (type) {
    'usdt' || 'crypto' || 'btc' || 'eth' => AppColors.gold,
    'bank' || 'bank_transfer' => AppColors.primary,
    'card' || 'credit' || 'debit' => AppColors.accent,
    'upi' => const Color(0xFF7C3AED),
    'skrill' || 'neteller' => AppColors.error,
    _ => AppColors.textSecondary,
  };

  IconData _iconForType(String type) => switch (type) {
    'usdt' || 'crypto' || 'btc' || 'eth' => Icons.currency_bitcoin_rounded,
    'bank' || 'bank_transfer' => Icons.account_balance_outlined,
    'card' || 'credit' || 'debit' => Icons.credit_card_outlined,
    'upi' => Icons.phone_android_rounded,
    'skrill' || 'neteller' => Icons.wallet_rounded,
    _ => Icons.payment_outlined,
  };
}

// ── Detail row ────────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11))),
      Expanded(child: Text(value,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12,
              fontWeight: FontWeight.w600))),
    ]),
  );
}

// ── Account picker sheet ──────────────────────────────────────────────────────
class _AccountPickerSheet extends StatelessWidget {
  final List<Mt5Account> accounts;
  final Mt5Account? selected;
  final ValueChanged<Mt5Account> onSelect;

  const _AccountPickerSheet({
    required this.accounts,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg100,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),

        Row(children: [
          const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          const Expanded(child: Text('Select MT5 Account',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
          Text('${accounts.length} account${accounts.length != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 4),
        const Text(
          'Funds will be credited to / debited from the selected account.',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),

        if (accounts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text('No MT5 accounts linked yet.\nGo to Profile → Link MT5 Account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final acc = accounts[i];
                final isSel = acc.id == selected?.id;
                return GestureDetector(
                  onTap: () { onSelect(acc); Navigator.pop(context); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primaryLighter : AppColors.bg200,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isSel ? AppColors.primary : AppColors.border,
                          width: isSel ? 1.5 : 1),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                            color: isSel ? AppColors.primary : AppColors.bg300,
                            shape: BoxShape.circle),
                        child: Icon(
                            isSel ? Icons.check_rounded : Icons.account_circle_outlined,
                            color: isSel ? Colors.white : AppColors.textMuted, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text('#${acc.login}',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                                  color: isSel ? AppColors.primary : AppColors.textPrimary)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: acc.isReal ? AppColors.successBg : AppColors.warningBg,
                                borderRadius: BorderRadius.circular(4)),
                            child: Text(acc.isReal ? 'REAL' : 'DEMO',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                                    color: acc.isReal ? AppColors.success : AppColors.warning)),
                          ),
                          // Warn if it's a seed account
                          if (int.tryParse(acc.id) == null) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AppColors.warningBg, borderRadius: BorderRadius.circular(4)),
                              child: const Text('SEED',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                                      color: AppColors.warning)),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 2),
                        Text('${acc.server}  ·  ${acc.type}  ·  ${acc.leverage}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        Row(children: [
                          _Stat('Balance', '\$${_fmt(acc.balance)}', AppColors.textPrimary),
                          const SizedBox(width: 14),
                          _Stat('Equity', '\$${_fmt(acc.equity)}', AppColors.bullish),
                        ]),
                      ])),
                    ]),
                  ),
                );
              },
            ),
          ),
      ]),
    );
  }

  String _fmt(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(2);
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
    Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  ]);
}
