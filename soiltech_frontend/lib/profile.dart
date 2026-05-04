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
  static const Color pageBg = Color(0xFFFDFDF8);
  static const Color titleColor = Color(0xFF173F2B);
  static const Color subtitleColor = Color(0xFF8A8F84);
  static const Color darkGreen = Color(0xFF2F6B31);
  static const Color mediumGreen = Color(0xFF5F9651);
  static const Color lightLime = Color(0xFFC9E454);
  static const Color dividerColor = Color(0xFFE7E9DA);
  static const Color inputBorder = Color(0xFFDCE3C7);
  static const Color whiteCard = Color(0xFFFFFEFB);

  static const String profileTopAsset = 'assets/logo/profile_bg_header.png';
  static const String profileBottomAsset = 'assets/logo/profile_bg.png';

  final ProfilePhotoController _photoController = ProfilePhotoController();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

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
      } else {
        if (mounted) setState(() => _isLoading = false);
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Sign Out',
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'No',
                style: TextStyle(color: subtitleColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _photoController.profileService.signOut();

                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                }
              },
              child: const Text(
                'Yes',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: pageBg,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: darkGreen),
            )
          : GestureDetector(
              onTap: () {
                if (showPictureMenu) {
                  setState(() => showPictureMenu = false);
                }
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(color: pageBg),
                  ),

                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Image.asset(
                        profileBottomAsset,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: h * 0.23,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  RefreshIndicator(
                    color: darkGreen,
                    onRefresh: _loadProfile,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: h),
                        child: Column(
                          children: [
                            _buildTopSection(w, h),

                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: w * 0.065,
                              ),
                              child: _buildProfileCard(w, h),
                            ),

                            SizedBox(height: h * 0.24),
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

  Widget _buildTopSection(double w, double h) {
    final double topInset = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: h * 0.34,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: double.infinity,
            height: h * 0.28,
            child: Image.asset(
              profileTopAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  color: const Color(0xFFEAF4C1),
                );
              },
            ),
          ),

          Positioned(
            top: topInset + 14,
            left: w * 0.055,
            right: w * 0.055,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: w * 0.10,
                    height: w * 0.10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F8D6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: darkGreen,
                      size: w * 0.055,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _handleSignOut,
                  child: Container(
                    width: w * 0.10,
                    height: w * 0.10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F8D6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: darkGreen,
                      size: w * 0.055,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: topInset + h * 0.05,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Profile',
                  style: TextStyle(
                    color: darkGreen,
                    fontSize: w * 0.072,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: h * 0.006),
                Text(
                  'Manage your account and preferences',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: w * 0.032,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: w * 0.30,
                    height: w * 0.30,
                    padding: EdgeInsets.all(w * 0.010),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _buildProfileImage(w * 0.22),
                    ),
                  ),
                  Positioned(
                    bottom: w * 0.005,
                    right: -w * 0.005,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          showPictureMenu = !showPictureMenu;
                        });
                      },
                      child: Container(
                        width: w * 0.085,
                        height: w * 0.085,
                        decoration: BoxDecoration(
                          color: darkGreen,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: w * 0.042,
                        ),
                      ),
                    ),
                  ),
                  if (showPictureMenu)
                    Positioned(
                      top: w * 0.32,
                      right: -w * 0.12,
                      child: GestureDetector(
                        onTap: () {},
                        child: _pictureMenu(w),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(double w, double h) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        w * 0.05,
        h * 0.028,
        w * 0.05,
        h * 0.03,
      ),
      decoration: BoxDecoration(
        color: whiteCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF0F0E5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _isEditMode
              ? _buildEditableRow(
                  w: w,
                  h: h,
                  icon: Icons.person_outline_rounded,
                  label: 'Username',
                  controller: _usernameController,
                )
              : _buildInfoRow(
                  w: w,
                  h: h,
                  icon: Icons.person_outline_rounded,
                  label: 'Username',
                  value: _username.isNotEmpty ? _username : '—',
                ),

          SizedBox(height: h * 0.008),
          Container(height: 1, color: dividerColor),
          SizedBox(height: h * 0.008),

          _isEditMode
              ? _buildEditableRow(
                  w: w,
                  h: h,
                  icon: Icons.email_outlined,
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                )
              : _buildInfoRow(
                  w: w,
                  h: h,
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: _email.isNotEmpty ? _email : '—',
                ),

          SizedBox(height: h * 0.008),
          _buildDashedDivider(),
          SizedBox(height: h * 0.008),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: h * 0.014),
              child: Row(
                children: [
                  _buildPlainIcon(
                    w: w,
                    icon: Icons.lock_outline_rounded,
                  ),
                  SizedBox(width: w * 0.04),
                  Expanded(
                    child: Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: w * 0.048,
                        fontWeight: FontWeight.w900,
                        color: darkGreen,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: darkGreen,
                    size: w * 0.075,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: h * 0.008),
          Container(height: 1, color: dividerColor),
          SizedBox(height: h * 0.022),

          SizedBox(
            width: double.infinity,
            height: h * 0.07,
            child: _buildActionButton(w),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required double w,
    required double h,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: h * 0.01),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildPlainIcon(w: w, icon: icon),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: w * 0.042,
                    color: subtitleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: h * 0.005),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: w * 0.053,
                    color: darkGreen,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow({
    required double w,
    required double h,
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: h * 0.01),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: h * 0.022),
            child: _buildPlainIcon(w: w, icon: icon),
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: w * 0.042,
                    color: subtitleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: h * 0.008),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: TextStyle(
                    fontSize: w * 0.044,
                    fontWeight: FontWeight.w800,
                    color: darkGreen,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: w * 0.035,
                      vertical: h * 0.015,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: inputBorder,
                        width: 1.4,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: darkGreen,
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlainIcon({
    required double w,
    required IconData icon,
  }) {
    return SizedBox(
      width: w * 0.08,
      height: w * 0.08,
      child: Center(
        child: Icon(
          icon,
          color: darkGreen,
          size: w * 0.06,
        ),
      ),
    );
  }

  Widget _buildDashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.maxWidth / 8).floor();

        return Row(
          children: List.generate(dashCount, (index) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 1.3,
                color: const Color(0xFFE6E7D7),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildActionButton(double w) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: _isEditMode
            ? (_isSaving ? null : _handleSaveProfile)
            : _enterEditMode,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: _isSaving
                  ? [
                      mediumGreen.withOpacity(0.6),
                      lightLime.withOpacity(0.6),
                    ]
                  : const [
                      Color(0xFF649E56),
                      Color(0xFFC9E454),
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: darkGreen.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: w * 0.06,
                child: Icon(
                  Icons.eco_outlined,
                  color: Colors.white.withOpacity(0.85),
                  size: w * 0.07,
                ),
              ),
              Center(
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        _isEditMode ? 'Save Profile' : 'Edit Profile',
                        style: TextStyle(
                          fontSize: w * 0.05,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
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
      child: Icon(
        Icons.account_circle,
        size: iconSize,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _pictureMenu(double w) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.04,
            vertical: w * 0.03,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: inputBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _uploadProfilePhoto,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.camera_alt_rounded,
                        size: 17,
                        color: darkGreen,
                      ),
                      SizedBox(width: w * 0.02),
                      const Text(
                        'Upload Picture',
                        style: TextStyle(
                          fontSize: 13,
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (profileImageUrl != null && profileImageUrl!.isNotEmpty) ...[
                  SizedBox(height: w * 0.03),
                  GestureDetector(
                    onTap: _removeProfilePhoto,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.delete_rounded,
                          size: 17,
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Remove Picture',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
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