import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_try/final_project/services/database.dart';
import 'package:flutter_try/final_project/pages/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;
  String get _userEmail =>
      FirebaseAuth.instance.currentUser?.email ?? 'No email';
  String get _displayName {
    final email = _userEmail;
    return email.contains('@') ? email.split('@').first : email;
  }

  final DatabaseMethods _db = DatabaseMethods();
  bool _notificationsEnabled = true;

  Stream<double> get _balanceStream {
    if (_userId == null) return Stream.value(0.0);
    return _db.getBalanceStream(_userId!);
  }

  Stream<double> get _expensesStream {
    if (_userId == null) return Stream.value(0.0);
    return _db.getExpenses(_userId!).map((snapshot) {
      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['archived'] == true) continue;
        if (data['type'] == 'Expenses') {
          total += (data['amount'] as num?)?.toDouble() ?? 0;
        }
      }
      return total;
    });
  }

  Stream<double> get _incomeStream {
    if (_userId == null) return Stream.value(0.0);
    return _db.getIncomes(_userId!).map((snapshot) {
      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['archived'] == true) continue;
        total += (data['amount'] as num?)?.toDouble() ?? 0;
      }
      return total;
    });
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
        (route) => false,
      );
    }
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Widget? trailing,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: (iconColor ?? const Color(0xFFEAD25B)).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              size: 20, color: iconColor ?? const Color(0xFFEAD25B)),
        ),
        title: Text(label,
            style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        trailing: trailing ??
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFEAD25B)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _balanceTile(String label, String amount, Color amountColor) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style:
                  TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              amount,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: amountColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.7, 1.0],
            colors: [
              Color(0xFFFFFAF0),
              Color(0xFFFFFAF0),
              Color(0xFFEAD25B),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20, color: Color(0xFFEAD25B)),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Back',
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Account",
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                const Color(0xFFEAD25B).withOpacity(0.2),
                            child: const Icon(Icons.person_rounded,
                                size: 30, color: Color(0xFFEAD25B)),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hi, $_displayName",
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _userEmail,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Divider(color: Colors.grey.shade100, height: 1),
                      const SizedBox(height: 16),

                      StreamBuilder<double>(
                        stream: _balanceStream,
                        builder: (_, balSnap) {
                          return StreamBuilder<double>(
                            stream: _incomeStream,
                            builder: (_, incSnap) {
                              return StreamBuilder<double>(
                                stream: _expensesStream,
                                builder: (_, expSnap) {
                                  final loading =
                                      balSnap.connectionState ==
                                              ConnectionState.waiting ||
                                          incSnap.connectionState ==
                                              ConnectionState.waiting ||
                                          expSnap.connectionState ==
                                              ConnectionState.waiting;

                                  if (loading) {
                                    return const SizedBox(
                                      height: 40,
                                      child: Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFFEAD25B))),
                                    );
                                  }

                                  final balance = balSnap.data ?? 0.0;
                                  final income  = incSnap.data ?? 0.0;
                                  final expenses = expSnap.data ?? 0.0;

                                  return Row(
                                    children: [
                                      _balanceTile("Balance",
                                          "₱${balance.toStringAsFixed(2)}",
                                          Colors.black87),
                                      Container(
                                          width: 1,
                                          height: 36,
                                          color: Colors.grey.shade200),
                                      _balanceTile("Income",
                                          "₱${income.toStringAsFixed(2)}",
                                          Colors.green),
                                      Container(
                                          width: 1,
                                          height: 36,
                                          color: Colors.grey.shade200),
                                      _balanceTile("Expenses",
                                          "₱${expenses.toStringAsFixed(2)}",
                                          Colors.red),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text("Preferences",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5)),
                const SizedBox(height: 10),

                _menuTile(
                  icon: Icons.notifications_rounded,
                  label: "Notifications",
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (val) =>
                        setState(() => _notificationsEnabled = val),
                    activeColor: const Color(0xFFEAD25B),
                  ),
                ),

                const SizedBox(height: 14),

                Text("Support",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5)),
                const SizedBox(height: 10),

                _menuTile(
                    icon: Icons.thumb_up_alt_rounded,
                    label: "Rate our app",
                    onTap: () {}),
                _menuTile(
                    icon: Icons.info_outline_rounded,
                    label: "About Peso Pilot",
                    onTap: () {}),
                _menuTile(
                    icon: Icons.headset_mic_rounded,
                    label: "Contact Us",
                    onTap: () {}),

                const SizedBox(height: 14),

                Text("Account",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5)),
                const SizedBox(height: 10),

                _menuTile(
                    icon: Icons.settings_rounded,
                    label: "Settings",
                    onTap: () {}),

                _menuTile(
                  icon: Icons.logout_rounded,
                  label: "Log Out",
                  iconColor: Colors.redAccent,
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Colors.redAccent),
                  onTap: _confirmLogout,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}