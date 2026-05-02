import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soiltech/controllers/profile_photo_controller.dart';
import 'package:soiltech/controllers/profile_info_controller.dart';
import 'package:soiltech/login.dart';
import 'package:soiltech/change_password_screen.dart';

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

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: darkGreen))
          : GestureDetector(
              onTap: () {
                if (showPictureMenu) setState(() => showPictureMenu = false);
              },
              child: Stack(
                children: [
                  // ── Gradient header ───────────────────────────────
                  Container(
                    height: h * 0.32,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [darkGreen, greenColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),

                  SafeArea(
                    child: RefreshIndicator(
                      color: darkGreen,
                      onRefresh: _loadProfile,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            // ── Top bar ─────────────────────────────
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: w * 0.04,
                                vertical: h * 0.02,
                              ),
                              child: Row(
                                children: [
                                  // Back arrow
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Icon(
                                      Icons.arrow_back_ios,
                                      color: Colors.white,
                                      size: w * 0.065,
                                    ),
                                  ),

                                  const Spacer(),

                                  // Title
                                  Text(
                                    'Profile',
                                    style: TextStyle(
                                      fontSize: w * 0.06,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),

                                  const Spacer(),

                                  // Logout button
                                  GestureDetector(
                                    onTap: _handleSignOut,
                                    child: Container(
                                      padding: EdgeInsets.all(w * 0.02),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.25),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.logout_rounded,
                                        color: Colors.white,
                                        size: w * 0.055,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: h * 0.015),

                            // ── Avatar + camera ─────────────────────
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: w * 0.26,
                                  height: w * 0.26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade300,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: _buildProfileImage(w * 0.15),
                                  ),
                                ),

                                // Camera button
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => showPictureMenu = !showPictureMenu,
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.all(w * 0.016),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: darkGreen,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: w * 0.038,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                                // ── Picture menu below camera icon ───
                                if (showPictureMenu)
                                  Positioned(
                                    top: w * 0.26 + 6,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap:
                                          () {}, // absorb tap — prevent dismiss
                                      child: _pictureMenu(w),
                                    ),
                                  ),
                              ],
                            ),

                            SizedBox(height: h * 0.09),

                            // ── Profile card ────────────────────────
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: w * 0.05,
                              ),
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
                                    // ── Username ──
                                    _buildFieldLabel('Username'),
                                    const SizedBox(height: 6),
                                    _isEditMode
                                        ? _buildTextField(_usernameController)
                                        : _buildDisplayText(_username),

                                    const SizedBox(height: 16),

                                    // ── Email ──
                                    _buildFieldLabel('Email'),
                                    const SizedBox(height: 6),
                                    _isEditMode
                                        ? _buildTextField(
                                            _emailController,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                          )
                                        : _buildDisplayText(_email),

                                    const SizedBox(height: 16),

                                    Divider(
                                      color: borderColor.withOpacity(0.3),
                                      thickness: 0.8,
                                    ),

                                    const SizedBox(height: 8),

                                    // ── Change Password row ──
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ChangePasswordScreen(),
                                          ),
                                        );
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

                                    // ── Action button ──
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
                                                disabledBackgroundColor:
                                                    darkGreen.withOpacity(0.6),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
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
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                            )
                                          : ElevatedButton(
                                              onPressed: _enterEditMode,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: darkGreen,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
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
                ],
              ),
            ),
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
          borderSide: const BorderSide(color: darkGreen, width: 1.5),
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
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.035,
            vertical: w * 0.025,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _uploadProfilePhoto,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.camera_alt,
                        size: 15,
                        color: Colors.black54,
                      ),
                      SizedBox(width: w * 0.018),
                      const Text(
                        'Upload Picture',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                if (profileImageUrl != null && profileImageUrl!.isNotEmpty) ...[
                  SizedBox(height: w * 0.02),
                  GestureDetector(
                    onTap: _removeProfilePhoto,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.delete, size: 15, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text(
                          'Remove Picture',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
