import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soiltech/controllers/profile_photo_controller.dart';
import 'package:soiltech/controllers/profile_info_controller.dart';
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

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  bool showPictureMenu = false;
  String? profileImageUrl;
  String? authUserId;
  String _username = '';
  String _email = '';
  bool _isLoading = true;
  bool _isEditMode = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      authUserId = Supabase.instance.client.auth.currentUser?.id;
      if (authUserId != null) {
        final data = await _photoController.profileService.getFarmerProfile();
        if (data != null && mounted) {
          setState(() {
            _username = data['username'] ?? '';
            _email = data['email'] ?? '';
            profileImageUrl = data['photo_url'];
            _usernameController.text = _username;
            _emailController.text = _email;
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

  void _enterEditMode() {
    _usernameController.text = _username;
    _emailController.text = _email;
    setState(() => _isEditMode = true);
  }

  void _cancelEditMode() {
    setState(() => _isEditMode = false);
  }

  Future<void> _handleSaveProfile() async {
    setState(() => _isSaving = true);

    final result = await ProfileController.handleSaveProfile(
      context: context,
      username: _usernameController,
      email: _emailController,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _username = _usernameController.text.trim();
        _email = _emailController.text.trim();
        _isEditMode = false;
      });
    }

    setState(() => _isSaving = false);
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
                  child: Column(
                    children: [
                      // ── Header / Avatar ──────────────────────────────
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

                                  // Logout icon
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

                                  // Camera button
                                  Positioned(
                                    bottom: -8,
                                    right: -8,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () =>
                                            showPictureMenu = !showPictureMenu,
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

                      // Username display
                      Text(
                        _username.isNotEmpty ? _username : '—',
                        style: TextStyle(
                          fontSize: w * 0.058,
                          fontWeight: FontWeight.w800,
                          color: darkGreen,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Email display
                      Text(
                        _email.isNotEmpty ? _email : '—',
                        style: TextStyle(
                          fontSize: w * 0.036,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Profile Card ─────────────────────────────────
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF8F2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: borderColor.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Username field ──
                              _buildFieldLabel('Username'),
                              const SizedBox(height: 6),
                              _isEditMode
                                  ? _buildTextField(_usernameController)
                                  : _buildDisplayText(_username),

                              const SizedBox(height: 16),

                              // ── Email field ──
                              _buildFieldLabel('Email'),
                              const SizedBox(height: 6),
                              _isEditMode
                                  ? _buildTextField(
                                      _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                    )
                                  : _buildDisplayText(_email),

                              const SizedBox(height: 16),

                              // ── Divider ──
                              Divider(
                                color: borderColor.withOpacity(0.3),
                                thickness: 0.8,
                              ),

                              const SizedBox(height: 8),

                              // ── Change Password row ──
                              GestureDetector(
                                onTap: () {
                                  // TODO: Navigator.push to ChangePasswordScreen
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      size: 18,
                                      color: Colors.red.shade400,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Change Password',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey.shade400,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ── Action Button ──
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: _isEditMode
                                    ? ElevatedButton(
                                        onPressed: _isSaving
                                            ? null
                                            : _handleSaveProfile,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: darkGreen,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: darkGreen
                                              .withOpacity(0.6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: _isSaving
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Text(
                                                'Save Profile',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      )
                                    : ElevatedButton(
                                        onPressed: _enterEditMode,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: darkGreen,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          'Edit Profile',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),

      // Picture menu overlay
      floatingActionButton: showPictureMenu
          ? null
          : null, // handled in Stack below via body overlay
    );
  }

  // ── Reusable widgets ──────────────────────────────────────────

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade500,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildDisplayText(String value) {
    return Text(
      value.isNotEmpty ? value : '—',
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade800,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor.withOpacity(0.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: darkGreen, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildProfileImage(double iconSize) {
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return Image.network(
        profileImageUrl!,
        key: ValueKey(profileImageUrl),
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
