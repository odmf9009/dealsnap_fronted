import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _agreeToTerms = false;

  final _auth = AuthService();

  Future<void> _handleGoogleSignIn() async {
    final l10n = AppLocalizations.of(context);
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.agreeToTermsContinue)),
      );
      return;
    }
    setState(() => _loading = true);
    final user = await _auth.signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.welcomeUser(user.name)),
          backgroundColor: AppColors.brand,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.signUpFailed),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? size.width * 0.3 : 24,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.brand, AppColors.brandDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 20),
                    Text(l10n.createAccount,
                        style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text(l10n.joinThousands,
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 22, height: 22,
                  child: Checkbox(
                    value: _agreeToTerms,
                    activeColor: AppColors.brand,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(TextSpan(
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    children: [
                      TextSpan(text: l10n.agreeToThe),
                      TextSpan(text: l10n.termsOfService, style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w600)),
                      TextSpan(text: ' ${l10n.and} '),
                      TextSpan(text: l10n.privacyPolicy, style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w600)),
                    ],
                  )),
                ),
              ]),

              const SizedBox(height: 20),

              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _loading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.divider, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://www.google.com/favicon.ico',
                              width: 18, height: 18,
                              errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata_rounded, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Text(l10n.signUpWithGoogle, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(l10n.or, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ),
                const Expanded(child: Divider()),
              ]),

              const SizedBox(height: 20),

              Text(l10n.fullName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextFormField(
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'John Doe',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: AppColors.textMuted),
                ),
              ),

              const SizedBox(height: 14),

              Text(l10n.email, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.textMuted),
                ),
              ),

              const SizedBox(height: 14),

              Text(l10n.password, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextFormField(
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: AppColors.textMuted),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Text(l10n.confirmPassword, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextFormField(
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: AppColors.textMuted),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text(l10n.createAccount),
                ),
              ),

              const SizedBox(height: 24),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${l10n.alreadyHaveAccount} ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: Text(l10n.signIn, style: GoogleFonts.inter(color: AppColors.brand, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ]),

              const SizedBox(height: 32),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
