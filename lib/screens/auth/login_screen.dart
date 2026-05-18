import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;
  bool _loading = false;

  final _auth = AuthService();

  Future<void> _handleGoogleSignIn() async {
    final l10n = AppLocalizations.of(context);
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
          content: Text(l10n.signInFailed),
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
      body: Center(
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
                      width: 64,
                      height: 64,
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
                    Text(l10n.welcomeBack,
                        style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text(l10n.signInSubtitle,
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),

              const SizedBox(height: 36),

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
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://www.google.com/favicon.ico',
                              width: 18, height: 18,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.g_mobiledata_rounded, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Text(l10n.continueWithGoogle,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
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

              Text(l10n.email, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.textMuted),
                ),
              ),

              const SizedBox(height: 16),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(l10n.password, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text(l10n.forgotPassword, style: GoogleFonts.inter(fontSize: 13, color: AppColors.brand)),
                ),
              ]),
              const SizedBox(height: 6),
              TextFormField(
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20, color: AppColors.textMuted),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text(l10n.signIn),
                ),
              ),

              const SizedBox(height: 24),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${l10n.dontHaveAccount} ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: Text(l10n.signUp, style: GoogleFonts.inter(color: AppColors.brand, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ]),

              const SizedBox(height: 32),
              Text(
                l10n.signingInTerms,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
