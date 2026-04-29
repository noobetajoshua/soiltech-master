// lib/profile.dart

import 'package:flutter/material.dart';
import 'package:soiltech/services/profile/profile_service.dart';
import 'package:soiltech/login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Constants ──────────────────────────────────────────────
  static const bgColor = Color(0xFFF1EFEA);
  static const greenColor = Color(0xFFA8EA7A);
  static const darkGreen = Color.fromARGB(255, 114, 168, 127);
  static const borderColor = Color(0xFF7D9C74);

  // ── State ──────────────────────────────────────────────────
  final ProfileService _profileService = ProfileService();

  String _username = '';
  String _email = '';
  String? _photoUrl;
  bool _isLoading = true;

  // ── Lifecycle ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await _profileService.getFarmerProfile();

    if (data != null && mounted) {
      setState(() {
        _username = data['username'] ?? '';
        _email = data['email'] ?? '';
        _photoUrl = data['photo_url'];
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // ── Sign Out ───────────────────────────────────────────────

  void _handleSignOut() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _profileService.signOut();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    // Responsive sizing
    final avatarBoxWidth = w * 0.33;
    final avatarBoxHeight = h * 0.13;
    final avatarIconSize = w * 0.18;
    final headerHeight = h * 0.23;
    final bannerHeight = headerHeight * 0.79;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: darkGreen))
            : Column(
                children: [
                  // ── Header ────────────────────────────────
                  SizedBox(
                    height: headerHeight,
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // Green banner
                        Container(
                          height: bannerHeight,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: greenColor,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.elliptical(220, 90),
                              bottomRight: Radius.elliptical(220, 90),
                            ),
                          ),
                        ),

                        // Profile picture card + logout icon
                        Positioned(
                          top: bannerHeight * 0.68,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Avatar card
                              Container(
                                width: avatarBoxWidth,
                                height: avatarBoxHeight,
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 1.2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(27),
                                  child: _buildProfileImage(avatarIconSize),
                                ),
                              ),

                              // Logout icon — top right corner of avatar card
                              Positioned(
                                top: -10,
                                right: -10,
                                child: GestureDetector(
                                  onTap: _handleSignOut,
                                  child: Container(
                                    padding: EdgeInsets.all(w * 0.015),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.85),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: borderColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.logout,
                                      color: Colors.red,
                                      size: w * 0.05,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ── Username ──────────────────────────────
                  Text(
                    _username.isNotEmpty ? _username : '—',
                    style: TextStyle(
                      fontSize: w * 0.058,
                      fontWeight: FontWeight.w800,
                      color: darkGreen,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // ── Email ─────────────────────────────────
                  Text(
                    _email.isNotEmpty ? _email : '—',
                    style: TextStyle(
                      fontSize: w * 0.036,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const Spacer(),
                ],
              ),
      ),
    );
  }

  // ── Profile Image Builder ──────────────────────────────────

  Widget _buildProfileImage(double iconSize) {
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return Image.network(
        _photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultAvatar(iconSize),
      );
    }

    // Default asset — replace asset.png with actual image when ready
    return Image.asset(
      'assets/asset.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _defaultAvatar(iconSize),
    );
  }

  Widget _defaultAvatar(double iconSize) {
    return Center(
      child: Icon(Icons.account_circle, size: iconSize, color: darkGreen),
    );
  }
}
