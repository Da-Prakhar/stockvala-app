import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/glass_card.dart';

// KYC Step 1 — Personal Info
class KycPersonalScreen extends StatefulWidget {
  const KycPersonalScreen({super.key});
  @override
  State<KycPersonalScreen> createState() => _KycPersonalScreenState();
}

class _KycPersonalScreenState extends State<KycPersonalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dobCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _nationality;
  String? _gender;
  bool _isLoading = false;

  static const List<String> _nationalities = ['Indian', 'American', 'British', 'UAE', 'Singaporean', 'Other'];
  static const List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg100,
      appBar: _kycAppBar('Personal Information', 1, 5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _KycHeader(
                icon: Icons.person_outline_rounded,
                title: 'Tell Us About You',
                subtitle: 'This information is used for account verification',
              ),
              const SizedBox(height: 32),

              // Gender selector
              Text('Gender', style: AppTextStyles.labelLarge),
              const SizedBox(height: 10),
              Row(
                children: _genders.map((g) => Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _gender = g),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _gender == g ? AppColors.primary.withOpacity(0.15) : AppColors.bg300,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _gender == g ? AppColors.primary : AppColors.border,
                          width: _gender == g ? 1.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(g, style: AppTextStyles.labelMedium.copyWith(
                        color: _gender == g ? AppColors.primary : AppColors.textSecondary,
                      )),
                    ),
                  ),
                )).toList(),
              ),

              const SizedBox(height: 20),

              // Date of birth
              AppInput(
                label: 'Date of Birth',
                hint: 'DD / MM / YYYY',
                controller: _dobCtrl,
                readOnly: true,
                prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.textMuted, size: 18),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime(1990),
                    firstDate: DateTime(1940),
                    lastDate: DateTime.now().subtract(const Duration(days: 6570)),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary)),
                      child: child!,
                    ),
                  );
                  if (date != null) {
                    _dobCtrl.text = '${date.day.toString().padLeft(2, '0')} / ${date.month.toString().padLeft(2, '0')} / ${date.year}';
                  }
                },
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 20),

              // Nationality
              Text('Nationality', style: AppTextStyles.labelLarge),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.bg500,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _nationality,
                    hint: Text('Select nationality', style: AppTextStyles.bodyMedium),
                    dropdownColor: AppColors.bg400,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                    items: _nationalities.map((n) => DropdownMenuItem(
                      value: n,
                      child: Text(n, style: AppTextStyles.bodyLarge),
                    )).toList(),
                    onChanged: (v) => setState(() => _nationality = v),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              AppInput(
                label: 'Residential Address',
                hint: 'Enter your full address',
                controller: _addressCtrl,
                maxLines: 3,
                prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 20),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 32),

              AppButton(
                label: 'Continue',
                isLoading: _isLoading,
                suffixIcon: Icons.arrow_forward_rounded,
                onPressed: () {
                  if (_formKey.currentState!.validate() && _gender != null && _nationality != null) {
                    Navigator.pushNamed(context, AppRoutes.kycDocument);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// KYC Step 2 — Document Upload
class KycDocumentScreen extends StatefulWidget {
  const KycDocumentScreen({super.key});
  @override
  State<KycDocumentScreen> createState() => _KycDocumentScreenState();
}

class _KycDocumentScreenState extends State<KycDocumentScreen> {
  String? _selectedDoc;
  bool _frontUploaded = false;
  bool _backUploaded = false;

  final List<Map<String, dynamic>> _docTypes = [
    {'type': 'Passport', 'icon': Icons.book_outlined},
    {'type': 'National ID', 'icon': Icons.credit_card_outlined},
    {'type': "Driver's License", 'icon': Icons.directions_car_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg100,
      appBar: _kycAppBar('Document Upload', 2, 5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _KycHeader(
              icon: Icons.badge_outlined,
              title: 'Identity Document',
              subtitle: 'Upload a government-issued ID for verification',
            ),
            const SizedBox(height: 32),

            Text('Select Document Type', style: AppTextStyles.labelLarge),
            const SizedBox(height: 12),

            ..._docTypes.map((d) => GestureDetector(
              onTap: () => setState(() => _selectedDoc = d['type']),
              child: AnimatedContainer(
                duration: 200.ms,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedDoc == d['type'] ? AppColors.primary.withOpacity(0.1) : AppColors.bg200,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedDoc == d['type'] ? AppColors.primary : AppColors.border,
                    width: _selectedDoc == d['type'] ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(d['icon'] as IconData,
                        color: _selectedDoc == d['type'] ? AppColors.primary : AppColors.textMuted),
                    const SizedBox(width: 12),
                    Text(d['type'] as String, style: AppTextStyles.labelLarge),
                    const Spacer(),
                    if (_selectedDoc == d['type'])
                      const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            )),

            const SizedBox(height: 24),

            if (_selectedDoc != null) ...[
              Text('Upload Documents', style: AppTextStyles.labelLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _UploadBox(label: 'Front Side', uploaded: _frontUploaded,
                      onTap: () => setState(() => _frontUploaded = true))),
                  const SizedBox(width: 12),
                  Expanded(child: _UploadBox(label: 'Back Side', uploaded: _backUploaded,
                      onTap: () => setState(() => _backUploaded = true))),
                ],
              ),
              const SizedBox(height: 16),
              AppCard(
                backgroundColor: AppColors.warningBg,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Documents must be clear, valid, and not expired',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning))),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Continue',
                suffixIcon: Icons.arrow_forward_rounded,
                onPressed: _frontUploaded && _backUploaded
                    ? () => Navigator.pushNamed(context, AppRoutes.kycSelfie)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// KYC Step 3 — Selfie
class KycSelfieScreen extends StatefulWidget {
  const KycSelfieScreen({super.key});
  @override
  State<KycSelfieScreen> createState() => _KycSelfieScreenState();
}

class _KycSelfieScreenState extends State<KycSelfieScreen> {
  bool _selfieCaptered = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg100,
      appBar: _kycAppBar('Selfie Verification', 3, 5),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _KycHeader(
              icon: Icons.camera_alt_outlined,
              title: 'Take a Selfie',
              subtitle: 'We need to verify your identity matches your document',
            ),
            const SizedBox(height: 40),

            // Camera frame
            GestureDetector(
              onTap: () => setState(() => _selfieCaptered = true),
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selfieCaptered ? AppColors.success : AppColors.primary,
                    width: 3,
                  ),
                  color: AppColors.bg300,
                ),
                child: _selfieCaptered
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 80)
                    : const Icon(Icons.camera_front_rounded, color: AppColors.primary, size: 80),
              ),
            ).animate().scale(duration: 500.ms),

            const SizedBox(height: 32),

            // Tips
            ...[
              'Ensure your face is clearly visible',
              'Good lighting, no sunglasses',
              'Hold your phone at eye level',
            ].map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Text(tip, style: AppTextStyles.bodyMedium),
                ],
              ),
            )),

            const Spacer(),

            AppButton(
              label: _selfieCaptered ? 'Continue' : 'Take Selfie',
              prefixIcon: _selfieCaptered ? null : Icons.camera_alt_outlined,
              suffixIcon: _selfieCaptered ? Icons.arrow_forward_rounded : null,
              onPressed: _selfieCaptered
                  ? () => Navigator.pushNamed(context, AppRoutes.kycRiskProfile)
                  : () => setState(() => _selfieCaptered = true),
            ),
          ],
        ),
      ),
    );
  }
}

// KYC Risk Profile
class KycRiskProfileScreen extends StatefulWidget {
  const KycRiskProfileScreen({super.key});
  @override
  State<KycRiskProfileScreen> createState() => _KycRiskProfileScreenState();
}

class _KycRiskProfileScreenState extends State<KycRiskProfileScreen> {
  int _riskLevel = 0; // 0=none, 1=conservative, 2=moderate, 3=aggressive

  final List<Map<String, dynamic>> _risks = [
    {'label': 'Conservative', 'desc': 'Low risk, stable returns', 'icon': Icons.shield_outlined, 'color': AppColors.success},
    {'label': 'Moderate', 'desc': 'Balanced risk and reward', 'icon': Icons.balance_rounded, 'color': AppColors.warning},
    {'label': 'Aggressive', 'desc': 'High risk, high potential', 'icon': Icons.rocket_launch_outlined, 'color': AppColors.error},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg100,
      appBar: _kycAppBar('Risk Profile', 4, 5),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _KycHeader(
              icon: Icons.assessment_outlined,
              title: 'Your Risk Appetite',
              subtitle: 'This helps us tailor your investment recommendations',
            ),
            const SizedBox(height: 32),

            ..._risks.asMap().entries.map((e) {
              final i = e.key + 1;
              final risk = e.value;
              return GestureDetector(
                onTap: () => setState(() => _riskLevel = i),
                child: AnimatedContainer(
                  duration: 200.ms,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _riskLevel == i ? (risk['color'] as Color).withOpacity(0.1) : AppColors.bg200,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _riskLevel == i ? risk['color'] as Color : AppColors.border,
                      width: _riskLevel == i ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (risk['color'] as Color).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(risk['icon'] as IconData, color: risk['color'] as Color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(risk['label'] as String, style: AppTextStyles.headingSmall),
                            Text(risk['desc'] as String, style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      if (_riskLevel == i)
                        Icon(Icons.check_circle_rounded, color: risk['color'] as Color, size: 22),
                    ],
                  ),
                ),
              );
            }),

            const Spacer(),

            AppButton(
              label: 'Submit KYC',
              onPressed: _riskLevel > 0
                  ? () => Navigator.pushReplacementNamed(context, AppRoutes.kycSuccess)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// KYC Success
class KycSuccessScreen extends StatelessWidget {
  const KycSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 40)],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 64),
              ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
              const SizedBox(height: 40),
              Text('KYC Submitted!', style: AppTextStyles.displayMedium).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 12),
              Text(
                'Your documents are under review.\nThis usually takes 1-2 business days.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 32),
              AppCard(
                backgroundColor: AppColors.primaryLight.withOpacity(0.08),
                child: Column(
                  children: [
                    _StatusRow(label: 'Account Created', done: true),
                    _StatusRow(label: 'Email Verified', done: true),
                    _StatusRow(label: 'KYC Submitted', done: true),
                    _StatusRow(label: 'KYC Approved', done: false, pending: true),
                    _StatusRow(label: 'Start Trading', done: false),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms),
              const Spacer(),
              AppButton(
                label: 'Go to Dashboard',
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool done;
  final bool pending;
  const _StatusRow({required this.label, required this.done, this.pending = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: done ? AppColors.success : (pending ? AppColors.warning : AppColors.bg400),
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check_rounded : (pending ? Icons.schedule_rounded : Icons.circle_outlined),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.bodyMedium.copyWith(
            color: done ? AppColors.textPrimary : (pending ? AppColors.warning : AppColors.textMuted),
          )),
        ],
      ),
    );
  }
}

// Helpers
AppBar _kycAppBar(String title, int step, int total) {
  return AppBar(
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.headingSmall),
        Text('Step $step of $total', style: AppTextStyles.caption),
      ],
    ),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(4),
      child: LinearProgressIndicator(
        value: step / total,
        backgroundColor: AppColors.bg400,
        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
        minHeight: 3,
      ),
    ),
  );
}

class _KycHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _KycHeader({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headingMedium),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _UploadBox extends StatelessWidget {
  final String label;
  final bool uploaded;
  final VoidCallback onTap;
  const _UploadBox({required this.label, required this.uploaded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        height: 120,
        decoration: BoxDecoration(
          color: uploaded ? AppColors.successBg : AppColors.bg300,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: uploaded ? AppColors.success : AppColors.border,
            width: uploaded ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              uploaded ? Icons.check_circle_rounded : Icons.upload_file_outlined,
              color: uploaded ? AppColors.success : AppColors.textMuted,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.labelSmall.copyWith(
              color: uploaded ? AppColors.success : AppColors.textMuted,
            )),
          ],
        ),
      ),
    );
  }
}
