import 'package:flutter/material.dart';

import 'package:ramhis_app/features/auth/screens/signup_personal_info_screen.dart';
import 'package:ramhis_app/features/auth/screens/signup_verification_screen.dart';

class SignupAccountSecurityWidget extends StatefulWidget {
  const SignupAccountSecurityWidget({
    super.key,
    required this.accountType,
    required this.fullName,
    required this.email,
    required this.contactNumber,
    required this.birthdate,
    this.password = '',
    this.confirmPassword = '',
  });

  final String accountType;
  final String fullName;
  final String email;
  final String contactNumber;
  final String birthdate;
  final String password;
  final String confirmPassword;

  @override
  State<SignupAccountSecurityWidget> createState() =>
      _SignupAccountSecurityWidgetState();
}

class _SignupAccountSecurityWidgetState
    extends State<SignupAccountSecurityWidget> {
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  bool _passwordVisible1 = false;
  bool _passwordVisible2 = false;
  bool _useSamePassword = false;

  String get _accountName {
    if (widget.accountType == 'doctor') return 'Doctor Account';
    if (widget.accountType == 'volunteer') return 'Volunteer Account';
    return 'User Account';
  }

  @override
  void initState() {
    super.initState();

    _passwordController =
        TextEditingController(text: widget.password);

    _confirmPasswordController =
        TextEditingController(
      text: widget.confirmPassword,
    );

    _passwordController.addListener(() {
      if (_useSamePassword) {
        _confirmPasswordController.text =
            _passwordController.text;
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _goBack() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SignupPersonalInformationWidget(
          accountType: widget.accountType,
          fullName: widget.fullName,
          email: widget.email,
          contactNumber: widget.contactNumber,
          birthdate: widget.birthdate,
        ),
      ),
    );
  }

  void _goNext() {
    final password = _passwordController.text.trim();
    final confirmPassword =
        _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete both password fields.',
          ),
        ),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must be at least 8 characters long.',
          ),
        ),
      );
      return;
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must contain at least one uppercase letter',
          ),
        ),
      );
      return;
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must contain at least one lowercase letter',
          ),
        ),
      );
      return;
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must contain at least one number',
          ),
        ),
      );
      return;
    }

    if (!RegExp(r'[!@#\$%^&*]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must contain at least one special character (!@#\$%^&*)',
          ),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SignupProfessionalVerificationWidget(
          accountType: widget.accountType,
          fullName: widget.fullName,
          email: widget.email,
          contactNumber: widget.contactNumber,
          birthdate: widget.birthdate,
          password: password,
          confirmPassword: confirmPassword,
          prcLicenseNumber: '',
          specialty: '',
          hospitalClinic: '',
          organization: '',
          skills: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SignupStepScaffold(
      accountName: _accountName,
      stepLabel: 'Account Security',
      currentStep: 2,
      totalSteps: 4,
      onBack: _goBack,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          _buildLabel('Password'),

          _buildPasswordField(
            controller: _passwordController,
            hintText: 'Password',
            obscureText: !_passwordVisible1,
            onToggle: () {
              setState(() {
                _passwordVisible1 =
                    !_passwordVisible1;
              });
            },
          ),

          const SizedBox(height: 8),

          const Text(
            'Use at least 8 characters.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 16),

          CheckboxListTile(
            value: _useSamePassword,
            contentPadding: EdgeInsets.zero,
            activeColor:
                const Color(0xFF4267D6),
            controlAffinity:
                ListTileControlAffinity.leading,
            title: const Text(
              'Use same password for confirmation',
              style: TextStyle(
                color: Color(0xFF243B73),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _useSamePassword =
                    value ?? false;

                if (_useSamePassword) {
                  _confirmPasswordController
                          .text =
                      _passwordController.text;
                } else {
                  _confirmPasswordController
                      .clear();
                }
              });
            },
          ),

          const SizedBox(height: 12),

          _buildLabel('Confirm password'),

          _buildPasswordField(
            controller:
                _confirmPasswordController,
            hintText: 'Confirm password',
            enabled: !_useSamePassword,
            obscureText: !_passwordVisible2,
            onToggle: () {
              setState(() {
                _passwordVisible2 =
                    !_passwordVisible2;
              });
            },
          ),

          const SizedBox(height: 34),

          SizedBox(
            height: 58,
            child: ElevatedButton.icon(
              onPressed: _goNext,
              icon: const Icon(
                Icons.navigate_next_rounded,
                size: 28,
              ),
              label: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFF05261),
                foregroundColor: Colors.white,
                elevation: 10,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding:
          const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF243B73),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggle,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      style: const TextStyle(
        color: Color(0xFF334155),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: enabled
            ? Colors.white
            : Colors.grey.shade100,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: Color(0xFF4267D6),
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF4267D6),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _SignupStepScaffold extends StatelessWidget {
  const _SignupStepScaffold({
    required this.accountName,
    required this.stepLabel,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    required this.child,
  });

  final String accountName;
  final String stepLabel;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4169D8),
              Color(0xFF234AB3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 430,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,
                  children: [
                    Align(
                      alignment:
                          Alignment.centerLeft,
                      child: InkWell(
                        onTap: onBack,
                        borderRadius:
                            BorderRadius
                                .circular(16),
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration:
                              BoxDecoration(
                            color: Colors.white
                                .withValues(
                              alpha: 0.9,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),
                          child: const Icon(
                            Icons
                                .arrow_back_rounded,
                            color: Color(
                              0xFF4267D6,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'Create',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Color(0xFFEAF0FF),
                        fontSize: 30,
                        fontWeight:
                            FontWeight.w300,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      accountName,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 34),

                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        30,
                      ),
                      child:
                          LinearProgressIndicator(
                        value: progress,
                        color:
                            const Color(
                          0xFFF05261,
                        ),
                        backgroundColor:
                            Colors.white24,
                        minHeight: 7,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              Colors.white24,
                          child: Icon(
                            Icons
                                .lock_outline_rounded,
                            color:
                                Colors.white,
                          ),
                        ),

                        const SizedBox(
                            width: 12),

                        Text(
                          'Step $currentStep of $totalSteps\n$stepLabel',
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            height: 1.35,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(
                        20,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFEAF4FF,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(30),
                      ),
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}