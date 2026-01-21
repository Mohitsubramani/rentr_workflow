import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'features/auth/login_screen.dart';
import 'features/auth/role_selection_screen.dart';
import 'features/profile/create_profile_screen.dart';
import 'features/home/agent_home_screen.dart' as agent;
import 'features/home/contractor_home_screen.dart' as contractor;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rentr Workflow',
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // 🔄 Auth loading
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ Not logged in
        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        final user = authSnapshot.data!;

        // 🔄 User document listener
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // 🆕 User doc not created yet
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const RoleSelectionScreen();
            }

            final data =
                userSnapshot.data!.data() as Map<String, dynamic>;

            // 🔹 Role not selected
            if (!data.containsKey('role')) {
              return const RoleSelectionScreen();
            }

            // 🔹 Profile not created
            if (!data.containsKey('name')) {
              return const CreateProfileScreen();
            }

            // 🚀 Route by role
            if (data['role'] == 'agent') {
  return agent.AgentHomeScreen();
} else {
  return contractor.ContractorHomeScreen();
}

          },
        );
      },
    );
  }
}
