// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../providers/auth_provider.dart';

// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _nameController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmController = TextEditingController();

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _phoneController.dispose();
//     _nameController.dispose();
//     _passwordController.dispose();
//     _confirmController.dispose();
//     super.dispose();
//   }

//   Future<void> _submit(AuthProvider auth) async {
//     if (!_formKey.currentState!.validate()) return;
//     final success = await auth.register(
//       email: _emailController.text.trim(),
//       phoneNumber: _phoneController.text.trim(),
//       fullName: _nameController.text.trim(),
//       password: _passwordController.text,
//       confirmPassword: _confirmController.text,
//     );
//     if (!mounted) return;
//     if (success) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text('Account created. Please log in.')));
//       Navigator.of(context).pop();
//     } else if (auth.errorMessage != null) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final auth = context.watch<AuthProvider>();

//     return Scaffold(
//       appBar: AppBar(title: const Text('Register')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               TextFormField(
//                 controller: _nameController,
//                 decoration: const InputDecoration(labelText: 'Full name'),
//                 validator: (v) => (v == null || v.isEmpty) ? 'Full name is required' : null,
//               ),
//               const SizedBox(height: 12),
//               TextFormField(
//                 controller: _emailController,
//                 keyboardType: TextInputType.emailAddress,
//                 decoration: const InputDecoration(labelText: 'Email'),
//                 validator: (v) => (v == null || v.isEmpty) ? 'Email is required' : null,
//               ),
//               const SizedBox(height: 12),
//               TextFormField(
//                 controller: _phoneController,
//                 keyboardType: TextInputType.phone,
//                 decoration: const InputDecoration(labelText: 'Phone number (e.g. +919876543210)'),
//                 validator: (v) => (v == null || v.isEmpty) ? 'Phone number is required' : null,
//               ),
//               const SizedBox(height: 12),
//               TextFormField(
//                 controller: _passwordController,
//                 obscureText: true,
//                 decoration: const InputDecoration(labelText: 'Password'),
//                 validator: (v) =>
//                     (v == null || v.length < 8) ? 'Password must be at least 8 characters' : null,
//               ),
//               const SizedBox(height: 12),
//               TextFormField(
//                 controller: _confirmController,
//                 obscureText: true,
//                 decoration: const InputDecoration(labelText: 'Confirm password'),
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
//                         child: const Text('Create account'),
//                       ),
//                     ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
