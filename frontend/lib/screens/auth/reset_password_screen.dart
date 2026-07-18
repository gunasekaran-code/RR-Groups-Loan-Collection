// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../providers/auth_provider.dart';
// import 'login_screen.dart';

// class ResetPasswordScreen extends StatefulWidget {
//   final String email;
//   final String code;
//   const ResetPasswordScreen({super.key, required this.email, required this.code});

//   @override
//   State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
// }

// class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _passwordController = TextEditingController();
//   final _confirmController = TextEditingController();

//   @override
//   void dispose() {
//     _passwordController.dispose();
//     _confirmController.dispose();
//     super.dispose();
//   }

//   Future<void> _submit(AuthProvider auth) async {
//     if (!_formKey.currentState!.validate()) return;
//     final success = await auth.resetPassword(
//       email: widget.email,
//       code: widget.code,
//       newPassword: _passwordController.text,
//       confirmPassword: _confirmController.text,
//     );
//     if (!mounted) return;
//     if (success) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text('Password reset. Please log in.')));
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (_) => const LoginScreen()),
//         (route) => false,
//       );
//     } else if (auth.errorMessage != null) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final auth = context.watch<AuthProvider>();

//     return Scaffold(
//       appBar: AppBar(title: const Text('Reset Password')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               TextFormField(
//                 controller: _passwordController,
//                 obscureText: true,
//                 decoration: const InputDecoration(labelText: 'New password'),
//                 validator: (v) =>
//                     (v == null || v.length < 8) ? 'Password must be at least 8 characters' : null,
//               ),
//               const SizedBox(height: 12),
//               TextFormField(
//                 controller: _confirmController,
//                 obscureText: true,
//                 decoration: const InputDecoration(labelText: 'Confirm new password'),
//                 validator: (v) =>
//                     v != _passwordController.text ? 'Passwords do not match' : null,
//               ),
//               const SizedBox(height: 20),
//               auth.isLoading
//                   ? const CircularProgressIndicator()
//                   : SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: () => _submit(auth),
//                         child: const Text('Reset password'),
//                       ),
//                     ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
