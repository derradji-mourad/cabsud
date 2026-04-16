import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../localization/string.dart';
import 'package:cabsudapp/reuse/theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  String _selectedLanguage = 'fr';
  String _userName = '';
  String _userEmail = '';
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _loadSettings();
    _fetchUserInfo();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'fr';
    });
  }

  Future<void> _fetchUserInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && mounted) {
      setState(() {
        _userEmail = user.email ?? '';
        _userName = user.email ?? 'User';
      });
    }
  }

  Future<void> _changeLanguage(String? newLang) async {
    if (newLang != null && newLang != _selectedLanguage) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', newLang);
      Strings.load(newLang);
      if (mounted) {
        setState(() {
          _selectedLanguage = newLang;
        });
      }
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showTermsDialog() {
    final strings = Strings.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryGold.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 2,
                decoration: BoxDecoration(
                  gradient: AppTheme.subtleGoldGradient,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.termsOfService,
                style: const TextStyle(
                  color: AppTheme.primaryGold,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    strings.termsOfServiceContent,
                    style: TextStyle(
                      color: AppTheme.softWhite.withValues(alpha: 0.75),
                      fontSize: 14,
                      height: 1.65,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(
                      strings.cancel,
                      style: TextStyle(
                        color: AppTheme.softWhite.withValues(alpha: 0.45),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.subtleGoldGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        strings.agree,
                        style: const TextStyle(
                          color: AppTheme.richBlack,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _userInitials() {
    if (_userName.isEmpty) return '?';
    final parts = _userName.split('@');
    final name = parts.first;
    if (name.length >= 2) return name.substring(0, 2).toUpperCase();
    return name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final strings = Strings.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: AppTheme.luxuryBackgroundGradient,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomPadding),
              children: [
                _buildHeader(strings),
                const SizedBox(height: 28),
                _buildProfileCard(),
                const SizedBox(height: 20),
                _buildSectionLabel('PRÉFÉRENCES'),
                const SizedBox(height: 10),
                _buildSettingsCard(strings),
                const SizedBox(height: 32),
                _buildLogoutButton(strings),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Strings strings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (b) =>
                AppTheme.subtleGoldGradient.createShader(b),
            child: Text(
              strings.settingsTitle.toUpperCase(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGold.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: AppTheme.subtleGoldGradient,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.subtleGoldGradient,
                  ),
                  child: Center(
                    child: Text(
                      _userInitials(),
                      style: const TextStyle(
                        color: AppTheme.richBlack,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName.isEmpty ? '...' : _userName.split('@').first,
                        style: const TextStyle(
                          color: AppTheme.softWhite,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userEmail,
                        style: TextStyle(
                          color: AppTheme.softWhite.withValues(alpha: 0.45),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.primaryGold.withValues(alpha: 0.55),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(Strings strings) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryGold.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLuxuryTile(
            title: strings.languageTitle,
            icon: Icons.language_rounded,
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLanguage,
                dropdownColor: AppTheme.card,
                icon: Icon(
                  Icons.expand_more_rounded,
                  color: AppTheme.primaryGold.withValues(alpha: 0.6),
                  size: 20,
                ),
                style: TextStyle(
                  color: AppTheme.softWhite.withValues(alpha: 0.75),
                  fontSize: 14,
                ),
                items: const [
                  DropdownMenuItem(value: 'fr', child: Text('Français')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: _changeLanguage,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              color: AppTheme.primaryGold.withValues(alpha: 0.08),
              height: 1,
            ),
          ),
          _buildLuxuryTile(
            title: strings.termsAndPrivacy,
            icon: Icons.shield_outlined,
            onTap: _showTermsDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildLuxuryTile({
    required String title,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryGold, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppTheme.softWhite.withValues(alpha: 0.85),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.softWhite.withValues(alpha: 0.2),
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(Strings strings) {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: AppTheme.subtleGoldGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGold.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded,
                color: AppTheme.richBlack, size: 20),
            const SizedBox(width: 12),
            Text(
              strings.logoutButton.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.richBlack,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
