import '../../core/services/google_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // Email
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),

            const SizedBox(height: 16),

            // Password
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),

            const SizedBox(height: 24),

            // Login Button
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Login successful')),
                  );

                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message ?? 'Login failed')),
                  );
                }
              },
              child: const Text('Login'),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Continue with Google'),
                onPressed: () async {
                  try {
                    final result =
                      await GoogleAuthService().signInWithGoogle();

                    if (result != null && context.mounted) {
  // DO NOTHING – AuthGate will auto redirect
}
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Google sign-in failed'),
                    ),
                  );
                  }
                },
            ),


            // Navigate to Register
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text('Don’t have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}
