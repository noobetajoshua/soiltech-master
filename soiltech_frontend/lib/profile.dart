import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soiltech/controllers/profile_photo_controller.dart';
import 'package:soiltech/login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const bgColor = Color(0xFFF1EFEA);
  static const greenColor = Color(0xFFA8EA7A);
  static const darkGreen = Color.fromARGB(255, 114, 168, 127);
  static const borderColor = Color(0xFF7D9C74);

  final ProfilePhotoController _photoController = ProfilePhotoController();

  bool showPictureMenu = false;
  String? profileImageUrl;
  String? authUserId;
  String _username = '';
  String _email = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      authUserId = Supabase.instance.client.auth.currentUser?.id;
      if (authUserId != null) {
        final data = await _photoController.profileService.getFarmerProfile();
        print('DEBUG photo_url: ${data?['photo_url']}');
        if (data != null && mounted) {
          setState(() {
            _username = data['username'] ?? '';
            _email = data['email'] ?? '';
            profileImageUrl = data['photo_url'];
            _isLoading = false;
          });
        } else if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _uploadProfilePhoto() async {
    if (authUserId == null) return;
    setState(() => showPictureMenu = false);

    await _photoController.uploadProfilePhoto(
      context: context,
      authUserId: authUserId!,
      onSuccess: _loadProfile,
    );
  }

  void _removeProfilePhoto() async {
    if (authUserId == null) return;
    setState(() => showPictureMenu = false);

    await _photoController.removeProfilePhoto(
      context: context,
      authUserId: authUserId!,
      onSuccess: _loadProfile,
    );
  }

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
                await _photoController.profileService.signOut();
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

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

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
            : RefreshIndicator(
                color: darkGreen,
                onRefresh: _loadProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: h,
                    child: Stack(
                      children: [
                        Column(
                          children: [
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

                                  // Avatar card
                                  Positioned(
                                    top: bannerHeight * 0.68,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: avatarBoxWidth,
                                          height: avatarBoxHeight,
                                          decoration: BoxDecoration(
                                            color: bgColor,
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                            border: Border.all(
                                              color: borderColor,
                                              width: 1.2,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              27,
                                            ),
                                            child: _buildProfileImage(
                                              avatarIconSize,
                                            ),
                                          ),
                                        ),

                                        // Logout icon
                                        Positioned(
                                          top: -10,
                                          right: -10,
                                          child: GestureDetector(
                                            onTap: _handleSignOut,
                                            child: Container(
                                              padding: EdgeInsets.all(
                                                w * 0.015,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.85,
                                                ),
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

                                        // Camera button
                                        Positioned(
                                          bottom: -8,
                                          right: -8,
                                          child: GestureDetector(
                                            onTap: () => setState(
                                              () => showPictureMenu =
                                                  !showPictureMenu,
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.all(w * 0.02),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF7DB97D),
                                                    Color(0xFFA8EA7A),
                                                  ],
                                                ),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.camera_alt,
                                                size: w * 0.05,
                                                color: Colors.white,
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

                            // Username
                            Text(
                              _username.isNotEmpty ? _username : '—',
                              style: TextStyle(
                                fontSize: w * 0.058,
                                fontWeight: FontWeight.w800,
                                color: darkGreen,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Email
                            Text(
                              _email.isNotEmpty ? _email : '—',
                              style: TextStyle(
                                fontSize: w * 0.036,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),

                        // Picture menu overlay
                        if (showPictureMenu)
                          Positioned(
                            top: h * 0.22,
                            right: w * 0.28,
                            child: _pictureMenu(w),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProfileImage(double iconSize) {
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return Image.network(
        profileImageUrl!, // ← plain URL, no ?t=
        key: ValueKey(
          profileImageUrl,
        ), // ← this forces rebuild when URL changes
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultAvatar(iconSize),
      );
    }

    return Image.asset(
      'assets/logo/empty.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _defaultAvatar(iconSize),
    );
  }

  Widget _defaultAvatar(double iconSize) {
    return Center(
      child: Icon(Icons.account_circle, size: iconSize, color: darkGreen),
    );
  }

  Widget _pictureMenu(double w) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: w * 0.55,
          padding: EdgeInsets.all(w * 0.03),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _uploadProfilePhoto,
                child: Row(
                  children: [
                    const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.black54,
                    ),
                    SizedBox(width: w * 0.02),
                    const Text(
                      'Upload Picture',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (profileImageUrl != null && profileImageUrl!.isNotEmpty) ...[
                SizedBox(height: w * 0.03),
                GestureDetector(
                  onTap: _removeProfilePhoto,
                  child: Row(
                    children: const [
                      Icon(Icons.delete, size: 20, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text(
                        'Remove Picture',
                        style: TextStyle(fontSize: 14, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
