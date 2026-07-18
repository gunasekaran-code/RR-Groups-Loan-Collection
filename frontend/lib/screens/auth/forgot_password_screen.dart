import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // step 1
  final _step1Key = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();

  // step 2
  final _step2Key = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 1; // 1 = request otp, 2 = enter otp + new password
  bool _loading = false;
  String? _error;
  String? _info; // e.g. "Code sent to •••••1234" or demo OTP notice

  @override
  void dispose() {
    _emailController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_step1Key.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final res = await AuthApiService.instance.requestOtp(
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
      );
      setState(() {
        _step = 2;
        final sentTo = res['sent_to'];
        final emailMasked = res['email_masked'];
        _info = 'Code sent to ${sentTo ?? emailMasked ?? 'your registered contact'}.';
        // The backend only includes demo_otp when no email/SMS provider is
        // configured yet — remove this block once Mailer/Sms are wired up.
        if (res['demo_otp'] != null) {
          _info = '${_info!}\nDemo OTP (no SMS/email provider configured): ${res['demo_otp']}';
        }
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_step2Key.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthApiService.instance.resetPassword(
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
        otp: _otpController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please sign in.')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: AppColors.kBackground,
        elevation: 0,
        title: const Text('Reset password', style: TextStyle(color: AppColors.kTextDark)),
        iconTheme: const IconThemeData(color: AppColors.kTextDark),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_info != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.kGoldLight.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.kGold.withOpacity(0.5)),
                      ),
                      child: Text(_info!, style: const TextStyle(color: AppColors.kTextDark, fontSize: 13)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_step == 1) _buildStep1() else _buildStep2(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Verify your identity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.kTextDark)),
          const SizedBox(height: 4),
          const Text('Enter your registered email and mobile number.',
              style: TextStyle(fontSize: 13, color: AppColors.kTextMuted)),
          const SizedBox(height: 20),
          const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.kTextDark)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'you@company.com', prefixIcon: Icon(Icons.mail_outline, size: 20)),
            validator: (v) => (v == null || v.trim().isEmpty || !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 16),
          const Text('Registered mobile number',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.kTextDark)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '9xxxxxxxxx', prefixIcon: Icon(Icons.phone_outlined, size: 20)),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Mobile number is required' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _requestOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kGoldDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Send OTP', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Enter code & new password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.kTextDark)),
          const SizedBox(height: 4),
          const Text('The code expires in 5 minutes.', style: TextStyle(fontSize: 13, color: AppColors.kTextMuted)),
          const SizedBox(height: 20),
          const Text('OTP', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.kTextDark)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(hintText: '6-digit code', counterText: ''),
            validator: (v) => (v == null || v.trim().length != 6) ? 'Enter the 6-digit code' : null,
          ),
          const SizedBox(height: 12),
          const Text('New password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.kTextDark)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'At least 6 characters', prefixIcon: Icon(Icons.lock_outline, size: 20)),
            validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
          ),
          const SizedBox(height: 12),
          const Text('Confirm password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.kTextDark)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Re-enter new password', prefixIcon: Icon(Icons.lock_outline, size: 20)),
            validator: (v) => (v != _newPasswordController.text) ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kGoldDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Reset password', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loading
                ? null
                : () => setState(() {
                      _step = 1;
                      _error = null;
                      _info = null;
                    }),
            child: const Text('Change email or mobile number'),
          ),
        ],
      ),
    );
  }
}