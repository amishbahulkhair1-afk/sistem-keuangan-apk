import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  final AuthService authService;
  final ApiService apiService;
  final List<CategoryModel> categories;

  const ProfileScreen({
    super.key,
    required this.authService,
    required this.apiService,
    required this.categories,
  });

  void _showServerSettingsDialog(BuildContext context) {
    final controller = TextEditingController(text: authService.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.dns_rounded, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Ganti URL Server API', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gunakan http://10.0.2.2:8000 untuk Android Emulator, http://localhost:8000 untuk Web/Desktop, atau IP LAN komputer untuk HP fisik.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Base URL Backend',
                prefixIcon: const Icon(Icons.link_rounded, color: AppTheme.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              authService.setBaseUrl(controller.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  content: Text('URL Server disimpan: ${controller.text}'),
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Petugas', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // User Avatar & Info Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.glowShadow(AppTheme.primary),
                    ),
                    child: Center(
                      child: Text(
                        user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Petugas Lapangan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMain,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user?.email ?? '-',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (user?.role ?? 'petugas_lapangan').replaceAll('_', ' ').toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryDarker,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Settings Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _buildSettingTile(
                      icon: Icons.shield_outlined,
                      iconColor: AppTheme.primary,
                      title: 'Tingkat Hak Akses',
                      subtitle: user?.accessLevel ?? 'full',
                    ),
                    const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                    _buildSettingTile(
                      icon: Icons.dns_outlined,
                      iconColor: AppTheme.info,
                      title: 'URL Server Backend',
                      subtitle: authService.baseUrl,
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textLight),
                      onTap: () => _showServerSettingsDialog(context),
                    ),
                    const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                    _buildSettingTile(
                      icon: Icons.verified_outlined,
                      iconColor: AppTheme.purple,
                      title: 'Versi Aplikasi',
                      subtitle: 'v1.0.0 (Flutter Modern)',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Logout Button
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.expenseBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.expense.withValues(alpha: 0.2)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Konfirmasi Keluar'),
                        content: const Text('Apakah Anda yakin ingin keluar dari akun petugas?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.expense,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Keluar'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      authService.logout();
                    }
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded, color: AppTheme.expense, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Keluar dari Akun',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.expense,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textMain)),
      subtitle: Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
