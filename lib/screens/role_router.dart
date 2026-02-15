import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({
    super.key,
    required this.doctorHome,
    required this.patientHome,
  });

  final Widget doctorHome;
  final Widget patientHome;

  Future<String> _loadRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return (doc.data()?['role'] as String?) ?? 'patient';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadRole(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final role = snap.data!;
        return role == 'doctor' ? doctorHome : patientHome;
      },
    );
  }
}
