// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../providers/auth_provider.dart';
// import 'reset_password_screen.dart';

// class VerifyOtpScreen extends StatefulWidget {
//   final String email;
//   const VerifyOtpScreen({super.key, required this.email});

//   @override
//   State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
// }

// class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _codeController = TextEditingController();

//   @override
//   void dispose() {
//     _codeController.dispose();
//     super.dispose();
//   }

//   Future<void> _submit(AuthProvider auth) async {
//     if (!_formKey.currentState!.validate()) return;
//     final code = _codeController.text.trim();
//     final success = await auth.verifyOtp(email: widget.email, code: code);
//     if (!mounted) return;
//     if (success) {
//       Navigator.of(context).push(
//         MaterialPageRoute(
//           builder: (_) => ResetPasswordScreen(email: widget.email, code: code),
//         ),
//       );
//     } else if (auth.errorMessage != null) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final auth = context.watch<AuthProvider>();

//     return Scaffold(
//       appBar: AppBar(title: const Text('Verify Code')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text('Enter the code sent to ${widget.email}'),
//               const SizedBox(height: 12),
//               TextFormField(
//                 controller: _codeController,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(labelText: '6-digit code'),
//                 validator: (v) => (v == null || v.length < 4) ? 'Enter the code' : null,
//               ),
//               const SizedBox(height: 20),
//               auth.isLoading
//                   ? const CircularProgressIndicator()
//                   : SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: () => _submit(auth),
//                         child: const Text('Verify'),
//                       ),
//                     ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
