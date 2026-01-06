import 'dart:async';
import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String? initialRole;
  
  const RoleSelectionScreen({super.key, this.initialRole});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  late String selectedRole;
  bool _isLoading = false;

  // Form keys for different roles
  final _userFormKey = GlobalKey<FormState>();
  final _municipalFormKey = GlobalKey<FormState>();
  final _workersFormKey = GlobalKey<FormState>();

  // Controllers for User/Municipal (with registration)
  final _userEmailController = TextEditingController();
  final _userPasswordController = TextEditingController();
  final _userUsernameController = TextEditingController();
  final _userConfirmPasswordController = TextEditingController();
  final _userPhoneController = TextEditingController();
  final _userOtpController = TextEditingController();

  final _municipalEmailController = TextEditingController();
  final _municipalPasswordController = TextEditingController();
  final _municipalUsernameController = TextEditingController();
  final _municipalConfirmPasswordController = TextEditingController();

  // Controllers for Workers (with registration)
  final _workersEmailController = TextEditingController();
  final _workersPasswordController = TextEditingController();
  final _workersUsernameController = TextEditingController();
  final _workersConfirmPasswordController = TextEditingController();
  final _workersPhoneController = TextEditingController();
  final _workersOtpController = TextEditingController();
  String _selectedDepartment = 'Roads'; // Default department

  // Department options
  final List<String> _departments = [
    'Roads',
    'Solid Waste Management',
    'Electrical',
  ];

  // OTP verification states
  bool _isOtpSentUser = false;
  bool _isOtpVerifiedUser = false;
  bool _isOtpSentWorkers = false;
  bool _isOtpVerifiedWorkers = false;
  bool _isSendingOtp = false;
  
  // Resend OTP timer states
  int _resendTimerUser = 0;
  int _resendTimerWorkers = 0;
  Timer? _timerUser;
  Timer? _timerWorkers;

  // Tab controllers for User/Municipal/Workers
  bool _showUserRegister = false;
  bool _showMunicipalRegister = false;
  bool _showWorkersRegister = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    selectedRole = widget.initialRole ?? 'User';
  }

  @override
  void dispose() {
    // Dispose timers
    _timerUser?.cancel();
    _timerWorkers?.cancel();
    
    // Dispose controllers
    _userEmailController.dispose();
    _userPasswordController.dispose();
    _userUsernameController.dispose();
    _userConfirmPasswordController.dispose();
    _userPhoneController.dispose();
    _userOtpController.dispose();
    _municipalEmailController.dispose();
    _municipalPasswordController.dispose();
    _municipalUsernameController.dispose();
    _municipalConfirmPasswordController.dispose();
    _workersEmailController.dispose();
    _workersPasswordController.dispose();
    _workersUsernameController.dispose();
    _workersConfirmPasswordController.dispose();
    _workersPhoneController.dispose();
    _workersOtpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header Logo Section (matching second image style)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B7355),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.flag_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Civic Lens',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Report civic issues and track their resolution',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B6B6B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 32),

                // Role Chips - Centered
                _buildRoleChips(),
                const SizedBox(height: 32),

                // Login/Register Card - Centered
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildSelectedRoleForm(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= Role Chips =================

  Widget _buildRoleChips() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildRoleButton('User'),
          _buildRoleButton('Workers'),
          _buildRoleButton('Municipal'),
        ],
      ),
    );
  }

  Widget _buildRoleButton(String role) {
    final bool isSelected = selectedRole == role;
    IconData icon;
    switch (role) {
      case 'Workers':
        icon = Icons.engineering;
        break;
      case 'Municipal':
        icon = Icons.business;
        break;
      default:
        icon = Icons.person;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = role;
          _showUserRegister = false;
          _showMunicipalRegister = false;
          _showWorkersRegister = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B7355) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF8B7355),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              role,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF8B7355),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedRoleForm() {
    switch (selectedRole) {
      case 'Workers':
        return _buildWorkersForm();
      case 'Municipal':
        return _buildMunicipalForm();
      default:
        return _buildUserForm();
    }
  }

  // ================= User Forms =================

  Widget _buildUserForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Welcome ${_showUserRegister ? 'User' : 'back'}!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 24),

        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showUserRegister = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_showUserRegister ? const Color(0xFF8B7355) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Login',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: !_showUserRegister ? Colors.white : const Color(0xFF6B6B6B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showUserRegister = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _showUserRegister ? const Color(0xFF8B7355) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Register',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _showUserRegister ? Colors.white : const Color(0xFF6B6B6B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Form(
          key: _userFormKey,
          child: _showUserRegister ? _buildUserRegisterForm() : _buildUserLoginForm(),
        ),
      ],
    );
  }

  Widget _buildUserLoginForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextField(
          controller: _userEmailController,
          label: 'Email',
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your email';
            if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _userPasswordController,
          label: 'Password',
          hint: 'Enter your password',
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your password';
            return null;
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleUserLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B7355),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildUserRegisterForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextField(
          controller: _userUsernameController,
          label: 'Username',
          hint: 'Choose a username',
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter a username';
            if (value.length < 3) return 'Username must be at least 3 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _userEmailController,
          label: 'Email',
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your email';
            if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _userPhoneController,
          label: 'Phone Number',
          hint: 'Enter your phone number',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your phone number';
            if (value.length < 10) return 'Phone number must be at least 10 digits';
            return null;
          },
        ),
        const SizedBox(height: 16),
        // OTP verification section
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildTextField(
                controller: _userOtpController,
                label: 'OTP',
                hint: _isOtpSentUser ? 'Enter 6-digit OTP' : 'Send OTP first',
                keyboardType: TextInputType.number,
                enabled: _isOtpSentUser,
                validator: _isOtpSentUser ? (value) {
                  if (value == null || value.isEmpty) return 'Please enter OTP';
                  if (value.length != 6) return 'OTP must be 6 digits';
                  return null;
                } : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSendingOtp 
                        ? null 
                        : (_isOtpSentUser 
                            ? (_isOtpVerifiedUser ? null : _verifyOtpUser)
                            : _sendOtpUser),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isOtpVerifiedUser ? Colors.green : const Color(0xFF8B7355),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSendingOtp
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isOtpVerifiedUser 
                              ? 'Verified ✓' 
                              : (_isOtpSentUser ? 'Verify' : 'Send OTP'),
                            style: const TextStyle(fontSize: 12),
                          ),
                    ),
                  ),
                  if (_isOtpSentUser && !_isOtpVerifiedUser) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 35,
                      child: TextButton(
                        onPressed: _resendTimerUser > 0 || _isSendingOtp ? null : _resendOtpUser,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF8B7355),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(
                          _resendTimerUser > 0 
                            ? 'Resend (${_resendTimerUser}s)' 
                            : 'Resend OTP',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _userPasswordController,
          label: 'Password',
          hint: 'Create a password',
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter a password';
            if (value.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _userConfirmPasswordController,
          label: 'Confirm Password',
          hint: 'Confirm your password',
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please confirm your password';
            if (value != _userPasswordController.text) return 'Passwords do not match';
            return null;
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleUserRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B7355),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // ================= Municipal Forms =================

  Widget _buildMunicipalForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Municipal ${_showMunicipalRegister ? 'Registration' : 'Officer Login'}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 24),

        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showMunicipalRegister = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_showMunicipalRegister ? const Color(0xFF8B7355) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Login',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: !_showMunicipalRegister ? Colors.white : const Color(0xFF6B6B6B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showMunicipalRegister = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _showMunicipalRegister ? const Color(0xFF8B7355) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Register',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _showMunicipalRegister ? Colors.white : const Color(0xFF6B6B6B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Form(
          key: _municipalFormKey,
          child: _showMunicipalRegister ? _buildMunicipalRegisterForm() : _buildMunicipalLoginForm(),
        ),
      ],
    );
  }

  Widget _buildMunicipalLoginForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextField(
          controller: _municipalEmailController,
          label: 'Officer Email',
          hint: 'Enter officer email',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter officer email';
            if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _municipalPasswordController,
          label: 'Password',
          hint: 'Enter your password',
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your password';
            return null;
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleMunicipalLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B7355),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Text('Officer Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildMunicipalRegisterForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextField(
          controller: _municipalUsernameController,
          label: 'Officer Name',
          hint: 'Enter officer name',
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter officer name';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _municipalEmailController,
          label: 'Officer Email',
          hint: 'Enter officer email',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter officer email';
            if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _municipalPasswordController,
          label: 'Password',
          hint: 'Create a password',
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter a password';
            if (value.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _municipalConfirmPasswordController,
          label: 'Confirm Password',
          hint: 'Confirm your password',
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please confirm your password';
            if (value != _municipalPasswordController.text) return 'Passwords do not match';
            return null;
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleMunicipalRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B7355),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Text('Register Officer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // ================= Workers Forms =================

  Widget _buildWorkersForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Workers ${_showWorkersRegister ? 'Registration' : 'Portal Login'}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 24),

        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showWorkersRegister = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_showWorkersRegister ? const Color(0xFF8B7355) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Login',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: !_showWorkersRegister ? Colors.white : const Color(0xFF6B6B6B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showWorkersRegister = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _showWorkersRegister ? const Color(0xFF8B7355) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Register',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _showWorkersRegister ? Colors.white : const Color(0xFF6B6B6B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Form(
          key: _workersFormKey,
          child: _showWorkersRegister ? _buildWorkersRegisterForm() : _buildWorkersLoginForm(),
        ),
      ],
    );
  }

  Widget _buildWorkersLoginForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextField(
          controller: _workersEmailController,
          label: 'Worker Email',
          hint: 'Enter worker email',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter worker email';
            if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _workersPasswordController,
          label: 'Password',
          hint: 'Enter your password',
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your password';
            return null;
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleWorkersLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B7355),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Text('Worker Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkersRegisterForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextField(
          controller: _workersUsernameController,
          label: 'Worker Name',
          hint: 'Enter worker name',
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter worker name';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _workersEmailController,
          label: 'Worker Email',
          hint: 'Enter worker email',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter worker email';
            if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _workersPhoneController,
          label: 'Phone Number',
          hint: 'Enter worker phone number',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter phone number';
            if (value.length < 10) return 'Phone number must be at least 10 digits';
            return null;
          },
        ),
        const SizedBox(height: 16),
        // OTP verification section for Workers
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildTextField(
                controller: _workersOtpController,
                label: 'OTP',
                hint: _isOtpSentWorkers ? 'Enter 6-digit OTP' : 'Send OTP first',
                keyboardType: TextInputType.number,
                enabled: _isOtpSentWorkers,
                validator: _isOtpSentWorkers ? (value) {
                  if (value == null || value.isEmpty) return 'Please enter OTP';
                  if (value.length != 6) return 'OTP must be 6 digits';
                  return null;
                } : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSendingOtp 
                        ? null 
                        : (_isOtpSentWorkers 
                            ? (_isOtpVerifiedWorkers ? null : _verifyOtpWorkers)
                            : _sendOtpWorkers),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isOtpVerifiedWorkers ? Colors.green : const Color(0xFF8B7355),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSendingOtp
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isOtpVerifiedWorkers 
                              ? 'Verified ✓' 
                              : (_isOtpSentWorkers ? 'Verify' : 'Send OTP'),
                            style: const TextStyle(fontSize: 12),
                          ),
                    ),
                  ),
                  if (_isOtpSentWorkers && !_isOtpVerifiedWorkers) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 35,
                      child: TextButton(
                        onPressed: _resendTimerWorkers > 0 || _isSendingOtp ? null : _resendOtpWorkers,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF8B7355),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(
                          _resendTimerWorkers > 0 
                            ? 'Resend (${_resendTimerWorkers}s)' 
                            : 'Resend OTP',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDepartmentDropdown(),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _workersPasswordController,
          label: 'Password',
          hint: 'Create a password',
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter a password';
            if (value.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _workersConfirmPasswordController,
          label: 'Confirm Password',
          hint: 'Confirm your password',
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please confirm your password';
            if (value != _workersPasswordController.text) return 'Passwords do not match';
            return null;
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleWorkersRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B7355),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Text('Register Worker', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // ================= Shared Field Builder =================

  Widget _buildDepartmentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Department',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedDepartment,
            decoration: const InputDecoration(
              hintText: 'Select department',
              hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF8B7355), width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _departments.map((String department) {
              return DropdownMenuItem<String>(
                value: department,
                child: Text(department),
              );
            }).toList(),
            onChanged: (String? value) {
              if (value != null) {
                setState(() {
                  _selectedDepartment = value;
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a department';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isPassword = false,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF5F3F0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF8B7355), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  // ================= Authentication Methods =================

  Future<void> _handleUserLogin() async {
    if (_userFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.signInWithEmailAndPassword(
          _userEmailController.text.trim(),
          _userPasswordController.text.trim(),
        );
        Navigator.pushReplacementNamed(context, '/citizen');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleUserRegister() async {
    if (_userFormKey.currentState!.validate()) {
      // Check if OTP is verified
      if (!_isOtpVerifiedUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please verify your phone number first'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        await _authService.signUpWithEmailAndPassword(
          _userEmailController.text.trim(),
          _userPasswordController.text.trim(),
          _userUsernameController.text.trim(),
          phoneNumber: _userPhoneController.text.trim(),
          userType: 'citizen',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacementNamed(context, '/citizen');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleMunicipalLogin() async {
    if (_municipalFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.signInWithEmailAndPassword(
          _municipalEmailController.text.trim(),
          _municipalPasswordController.text.trim(),
        );
        Navigator.pushReplacementNamed(context, '/municipal-dashboard');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Officer login failed: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleMunicipalRegister() async {
    if (_municipalFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.signUpWithEmailAndPassword(
          _municipalEmailController.text.trim(),
          _municipalPasswordController.text.trim(),
          _municipalUsernameController.text.trim(),
          userType: 'municipal',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Officer account created!'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacementNamed(context, '/municipal-dashboard');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Officer registration failed: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleWorkersLogin() async {
    if (_workersFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.signInWithEmailAndPassword(
          _workersEmailController.text.trim(),
          _workersPasswordController.text.trim(),
        );
        Navigator.pushReplacementNamed(context, '/workers-dashboard');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Worker login failed: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleWorkersRegister() async {
    if (_workersFormKey.currentState!.validate()) {
      // Check if OTP is verified
      if (!_isOtpVerifiedWorkers) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please verify your phone number first'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        await _authService.signUpWithEmailAndPassword(
          _workersEmailController.text.trim(),
          _workersPasswordController.text.trim(),
          _workersUsernameController.text.trim(),
          phoneNumber: _workersPhoneController.text.trim(),
          userType: 'worker',
          department: _selectedDepartment,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Worker account created!'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacementNamed(context, '/workers-dashboard');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Worker registration failed: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Start resend timer for User OTP
  void _startResendTimerUser() {
    _resendTimerUser = 60; // 60 seconds
    _timerUser = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimerUser > 0) {
          _resendTimerUser--;
        } else {
          _timerUser?.cancel();
        }
      });
    });
  }

  // Start resend timer for Workers OTP
  void _startResendTimerWorkers() {
    _resendTimerWorkers = 60; // 60 seconds
    _timerWorkers = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimerWorkers > 0) {
          _resendTimerWorkers--;
        } else {
          _timerWorkers?.cancel();
        }
      });
    });
  }

  // Send OTP to User phone number
  Future<void> _sendOtpUser() async {
    String phoneNumber = _userPhoneController.text.trim();
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSendingOtp = true);
    try {
      print('UI: Sending OTP to User: $phoneNumber'); // Debug log
      await _authService.sendOTP(phoneNumber);
      setState(() {
        _isOtpSentUser = true;
        _isSendingOtp = false;
      });
      _startResendTimerUser(); // Start the resend timer
      
      // Check if it's a test number or real SMS
      String formattedNumber = phoneNumber;
      if (!formattedNumber.startsWith('+')) {
        formattedNumber = '+91$phoneNumber';
      }
      
      bool isTestNumber = ['1234567890', '9999999999', '9876543210'].contains(phoneNumber) ||
                         ['911234567890', '919999999999', '919876543210'].contains(phoneNumber.replaceAll('+', ''));
      
      if (isTestNumber) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test OTP sent successfully. Use 123456 to verify.'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully. Check your phone for SMS or use 123456 if SMS fails.'), backgroundColor: Colors.green),
        );
      }
      
      print('UI: OTP sent successfully to User'); // Debug log
    } catch (e) {
      print('UI: Failed to send OTP to User: $e'); // Debug log
      setState(() => _isSendingOtp = false);
      
      // If it's a billing error, show helpful message
      if (e.toString().contains('billing') || e.toString().contains('payment')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS service requires paid plan. Using test mode - enter 123456 as OTP.'), backgroundColor: Colors.orange),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Resend OTP to User phone number
  Future<void> _resendOtpUser() async {
    String phoneNumber = _userPhoneController.text.trim();
    setState(() => _isSendingOtp = true);
    try {
      await _authService.resendOTP(phoneNumber);
      setState(() => _isSendingOtp = false);
      _startResendTimerUser(); // Restart the timer
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _isSendingOtp = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resend OTP: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Verify OTP for User
  Future<void> _verifyOtpUser() async {
    String otp = _userOtpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      print('UI: Attempting to verify OTP: $otp'); // Debug log
      _authService.debugAuthState(); // Debug the auth service state
      
      bool isVerified = await _authService.verifyOTP(otp);
      print('UI: Verification result: $isVerified'); // Debug log
      
      if (isVerified) {
        setState(() {
          _isOtpVerifiedUser = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number verified successfully'), backgroundColor: Colors.green),
        );
      } else {
        // Handle case where verification returns false instead of throwing
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP verification failed. Please try again.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('UI: Verification error: $e'); // Debug log
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verification failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Send OTP to Workers phone number
  Future<void> _sendOtpWorkers() async {
    String phoneNumber = _workersPhoneController.text.trim();
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSendingOtp = true);
    try {
      print('UI: Sending OTP to Workers: $phoneNumber'); // Debug log
      await _authService.sendOTP(phoneNumber);
      setState(() {
        _isOtpSentWorkers = true;
        _isSendingOtp = false;
      });
      _startResendTimerWorkers(); // Start the resend timer
      
      // Check if it's a test number or real SMS
      String formattedNumber = phoneNumber;
      if (!formattedNumber.startsWith('+')) {
        formattedNumber = '+91$phoneNumber';
      }
      
      bool isTestNumber = ['1234567890', '9999999999', '9876543210'].contains(phoneNumber) ||
                         ['911234567890', '919999999999', '919876543210'].contains(phoneNumber.replaceAll('+', ''));
      
      if (isTestNumber) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test OTP sent successfully. Use 123456 to verify.'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully. Check your phone for SMS or use 123456 if SMS fails.'), backgroundColor: Colors.green),
        );
      }
      
      print('UI: OTP sent successfully to Workers'); // Debug log
    } catch (e) {
      print('UI: Failed to send OTP to Workers: $e'); // Debug log
      setState(() => _isSendingOtp = false);
      
      // If it's a billing error, show helpful message
      if (e.toString().contains('billing') || e.toString().contains('payment')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS service requires paid plan. Using test mode - enter 123456 as OTP.'), backgroundColor: Colors.orange),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Resend OTP to Workers phone number
  Future<void> _resendOtpWorkers() async {
    String phoneNumber = _workersPhoneController.text.trim();
    setState(() => _isSendingOtp = true);
    try {
      await _authService.resendOTP(phoneNumber);
      setState(() => _isSendingOtp = false);
      _startResendTimerWorkers(); // Restart the timer
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _isSendingOtp = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resend OTP: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Verify OTP for Workers
  Future<void> _verifyOtpWorkers() async {
    String otp = _workersOtpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      print('UI: Attempting to verify Workers OTP: $otp'); // Debug log
      bool isVerified = await _authService.verifyOTP(otp);
      print('UI: Workers verification result: $isVerified'); // Debug log
      
      if (isVerified) {
        setState(() {
          _isOtpVerifiedWorkers = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number verified successfully'), backgroundColor: Colors.green),
        );
      } else {
        // Handle case where verification returns false instead of throwing
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP verification failed. Please try again.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('UI: Workers verification error: $e'); // Debug log
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verification failed: $e'), backgroundColor: Colors.red),
      );
    }
  }
}