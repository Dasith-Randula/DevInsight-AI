import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/devinsight_api.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/auth_navigation.dart';

class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({
    super.key,
    this.initialName = '',
    this.initialEmail = '',
    this.initialStep = 0,
    this.authService,
  });

  final String initialName;
  final String initialEmail;
  final int initialStep;
  final AuthService? authService;

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  final _profileFormKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  final _companyController = TextEditingController();
  final _jobTitleController = TextEditingController();

  int _step = 0;
  String? _role;
  String? _roleError;
  final Set<String> _interests = {};
  bool _emailNotifications = true;
  bool _pushNotifications = false;
  bool _isLoadingState = true;
  bool _stateLoadFailed = false;
  bool _isSaving = false;
  String? _operationError;
  late final AuthService _authService;
  final Map<String, bool> _notificationCategories = {
    'Critical Risk Alerts': true,
    'Project Updates': true,
    'Issue Assignments': true,
    'AI Recommendations': true,
    'Project Activity': false,
  };

  static const _interestOptions = [
    _SelectionOption(
      'Code Quality & Issues',
      'Keep code health and open issues in focus.',
      Icons.bug_report_outlined,
    ),
    _SelectionOption(
      'Project Risk Prediction',
      'Spot delivery concerns before they grow.',
      Icons.shield_outlined,
    ),
    _SelectionOption(
      'Root Cause Analysis',
      'Understand what is behind recurring blockers.',
      Icons.account_tree_outlined,
    ),
    _SelectionOption(
      'Issue Prioritization',
      'Bring the most important work forward.',
      Icons.low_priority_rounded,
    ),
    _SelectionOption(
      'Team Productivity',
      'See patterns that help teams work better.',
      Icons.groups_outlined,
    ),
    _SelectionOption(
      'AI Recommendations',
      'Get practical, data-informed next steps.',
      Icons.auto_awesome_outlined,
    ),
    _SelectionOption(
      'Project Performance Insights',
      'Understand progress across your projects.',
      Icons.insights_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _step = widget.initialStep.clamp(0, 2);
    _nameController = TextEditingController(text: widget.initialName);
    _usernameController = TextEditingController();
    _emailController = TextEditingController(text: widget.initialEmail);
    _loadSavedState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_isSaving || _isLoadingState) return;
    if (_step > 0) {
      setState(() {
        _operationError = null;
        _step -= 1;
      });
      return;
    }
    Navigator.of(context).maybePop();
  }

  Future<void> _loadSavedState() async {
    if (_stateLoadFailed && mounted) {
      setState(() {
        _isLoadingState = true;
        _stateLoadFailed = false;
        _operationError = null;
      });
    }
    try {
      final saved = await _authService.fetchOnboardingState();
      if (!mounted) return;
      if (saved.nextStep == 'developer_home' ||
          saved.nextStep == 'manager_home') {
        await AuthNavigation.replaceFromDestination(
          context,
          saved.nextStep,
          fullName: saved.profile.fullName ?? widget.initialName,
          email: widget.initialEmail,
        );
        return;
      }

      setState(() {
        _nameController.text = saved.profile.fullName ?? widget.initialName;
        _usernameController.text = saved.profile.username ?? '';
        _companyController.text = saved.profile.organization ?? '';
        _jobTitleController.text = saved.profile.jobTitle ?? '';
        _role = switch (saved.profile.role) {
          'developer' => 'Developer',
          'project_manager' => 'Project Manager',
          _ => null,
        };
        _interests
          ..clear()
          ..addAll(saved.interests);
        _emailNotifications = saved.emailEnabled ?? true;
        _pushNotifications = saved.pushEnabled ?? false;
        for (final topic in _notificationCategories.keys) {
          _notificationCategories[topic] = saved.notificationTopics.contains(
            topic,
          );
        }
        _step = switch (saved.nextStep) {
          'profile' => 0,
          'preferences' => 1,
          'notifications' || 'complete' => 2,
          _ => widget.initialStep.clamp(0, 2),
        };
        _isLoadingState = false;
        _stateLoadFailed = false;
        _operationError = null;
      });
    } on AuthIntegrationException catch (error) {
      _setStateLoadError(error.message);
    } on DevInsightApiException catch (error) {
      _setStateLoadError(error.message);
    }
  }

  void _setStateLoadError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoadingState = false;
      _stateLoadFailed = true;
      _operationError = message;
    });
  }

  Future<void> _goNext() async {
    if (_isSaving || _isLoadingState) return;
    if (_step == 0) {
      final valid = _profileFormKey.currentState?.validate() ?? false;
      if (_role == null) {
        setState(() => _roleError = 'Choose a role to continue.');
      }
      if (!valid || _role == null) return;
    }

    setState(() {
      _isSaving = true;
      _operationError = null;
      _roleError = null;
    });
    try {
      if (_step == 0) {
        await _authService.saveOnboardingProfile(
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          organization: _companyController.text.trim().isEmpty
              ? null
              : _companyController.text.trim(),
          jobTitle: _jobTitleController.text.trim().isEmpty
              ? null
              : _jobTitleController.text.trim(),
          role: _role == 'Developer' ? 'developer' : 'project_manager',
        );
      } else {
        await _authService.saveOnboardingPreferences(
          _interestOptions
              .map((option) => option.title)
              .where(_interests.contains)
              .toList(),
        );
      }
      if (!mounted) return;
      setState(() => _step = (_step + 1).clamp(0, 2));
    } on AuthIntegrationException catch (error) {
      _setOperationError(error.message);
    } on DevInsightApiException catch (error) {
      _setOperationError(error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isSaving || _isLoadingState) return;
    setState(() {
      _isSaving = true;
      _operationError = null;
    });
    try {
      await _authService.saveOnboardingNotifications(
        emailEnabled: _emailNotifications,
        pushEnabled: _pushNotifications,
        topics: _notificationCategories.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList(),
      );
      final result = await _authService.completeOnboarding();
      if (!mounted) return;
      await AuthNavigation.replaceFromDestination(
        context,
        result.nextStep,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );
    } on AuthIntegrationException catch (error) {
      _setOperationError(error.message);
    } on DevInsightApiException catch (error) {
      _setOperationError(error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _setOperationError(String message) {
    if (!mounted) return;
    setState(() {
      _stateLoadFailed = false;
      _operationError = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light.copyWith(
        scaffoldBackgroundColor: AppColors.authBackground,
        colorScheme: AppTheme.light.colorScheme.copyWith(
          primary: AppColors.royalBlue,
          secondary: AppColors.azureBlue,
          surface: Colors.white,
          onSurface: AppColors.authText,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.authBackground,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppColors.authBackground,
                Color(0xFFE9EDFF),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 700;
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16 : 32,
                    vertical: compact ? 20 : 36,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: _buildCard(compact: compact),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required bool compact}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 24 : 30),
        border: Border.all(color: const Color(0xFFDCE7FF)),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.1),
            blurRadius: 44,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: EdgeInsets.all(compact ? 22 : 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBrandHeader(compact: compact),
          SizedBox(height: compact ? 28 : 38),
          _buildProgress(compact: compact),
          SizedBox(height: compact ? 28 : 36),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.025, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey<int>(_step),
              child: _buildStepContent(compact: compact),
            ),
          ),
          if (_isLoadingState) ...[
            const SizedBox(height: 18),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 8),
            Text(
              'Loading your saved onboarding details…',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.authSecondaryText,
                fontSize: 12,
              ),
            ),
          ],
          if (_operationError != null) ...[
            const SizedBox(height: 18),
            _buildOperationMessage(),
          ],
          SizedBox(height: compact ? 26 : 34),
          _buildActions(compact: compact),
          const SizedBox(height: 22),
          _buildPrototypeNotice(),
        ],
      ),
    );
  }

  Widget _buildOperationMessage() {
    final loadFailed = _stateLoadFailed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _operationError!,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.authText,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          if (loadFailed) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: _isSaving ? null : _loadSavedState,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBrandHeader({required bool compact}) {
    return Row(
      children: [
        Image.asset(
          AppAssets.devInsightBrandingLogo,
          width: 38,
          height: 38,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: 'Dev', style: _brandStyle(Colors.black)),
              TextSpan(
                text: 'Insight',
                style: _brandStyle(AppColors.royalBlue),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (!compact)
          Text(
            'FIRST-TIME SETUP',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.authSecondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.15,
            ),
          )
        else
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.azureBlue,
            size: 20,
          ),
      ],
    );
  }

  TextStyle _brandStyle(Color color) => GoogleFonts.plusJakartaSans(
    color: color,
    fontSize: 19,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  Widget _buildProgress({required bool compact}) {
    const labels = ['Profile', 'Preferences', 'Notifications'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(labels.length, (index) {
            final done = index < _step;
            final active = index == _step;
            return Expanded(
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: done || active
                          ? const LinearGradient(
                              colors: [
                                AppColors.royalBlue,
                                AppColors.azureBlue,
                              ],
                            )
                          : null,
                      color: done || active ? null : const Color(0xFFF2F5FB),
                      border: Border.all(
                        color: done || active
                            ? Colors.transparent
                            : const Color(0xFFDCE5F2),
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: AppColors.royalBlue.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: done
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : Text(
                              '${index + 1}',
                              style: GoogleFonts.plusJakartaSans(
                                color: active
                                    ? Colors.white
                                    : AppColors.authSecondaryText,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ),
                  if (index < labels.length - 1)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: index < _step
                            ? AppColors.azureBlue
                            : const Color(0xFFE6ECF5),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        if (!compact) ...[
          const SizedBox(height: 10),
          Row(
            children: List.generate(labels.length, (index) {
              return Expanded(
                child: Text(
                  labels[index],
                  textAlign: index == 0
                      ? TextAlign.left
                      : index == labels.length - 1
                      ? TextAlign.right
                      : TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: index == _step
                        ? AppColors.authText
                        : AppColors.authSecondaryText,
                    fontSize: 12,
                    fontWeight: index == _step
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              );
            }),
          ),
        ],
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_step + 1) / 3,
            minHeight: 5,
            backgroundColor: const Color(0xFFEDF1F8),
            valueColor: const AlwaysStoppedAnimation(AppColors.royalBlue),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent({required bool compact}) {
    switch (_step) {
      case 0:
        return _buildProfileStep(compact: compact);
      case 1:
        return _buildPreferencesStep(compact: compact);
      default:
        return _buildNotificationsStep(compact: compact);
    }
  }

  Widget _buildStepHeading({
    required String eyebrow,
    required String title,
    required String description,
    required bool compact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.royalBlue,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.authText,
            fontSize: compact ? 26 : 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1.16,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          description,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.authSecondaryText,
            fontSize: 14,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProfileStep({required bool compact}) {
    return Form(
      key: _profileFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeading(
            eyebrow: 'Step 01 · Your profile',
            title: "Let's Set Up Your Profile",
            description:
                'A little context helps DevInsight shape a clearer project workspace for you.',
            compact: compact,
          ),
          _responsivePair(
            compact: compact,
            first: _textField(
              controller: _nameController,
              label: 'Full name',
              hint: 'e.g. Alex Morgan',
              icon: Icons.person_outline_rounded,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your name'
                  : null,
            ),
            second: _textField(
              controller: _usernameController,
              label: 'Username',
              hint: 'Choose a username',
              icon: Icons.alternate_email_rounded,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Choose a username'
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          _textField(
            controller: _emailController,
            label: 'Email address',
            hint: 'name@company.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            readOnly: widget.initialEmail.isNotEmpty,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter your email address';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _responsivePair(
            compact: compact,
            first: _textField(
              controller: _companyController,
              label: 'Company / organization',
              hint: 'Optional',
              icon: Icons.apartment_rounded,
            ),
            second: _textField(
              controller: _jobTitleController,
              label: 'Job title',
              hint: 'Optional',
              icon: Icons.work_outline_rounded,
            ),
          ),
          const SizedBox(height: 24),
          _sectionLabel('Choose your role', 'Your role shapes your workspace.'),
          const SizedBox(height: 12),
          _responsivePair(
            compact: compact,
            first: _roleCard(
              role: 'Developer',
              subtitle: 'Build, review, and improve software projects.',
              icon: Icons.code_rounded,
            ),
            second: _roleCard(
              role: 'Project Manager',
              subtitle: 'Plan delivery and keep teams aligned.',
              icon: Icons.view_kanban_outlined,
            ),
          ),
          if (_roleError != null) ...[
            const SizedBox(height: 8),
            Text(
              _roleError!,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreferencesStep({required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeading(
          eyebrow: 'Step 02 · Your focus',
          title: 'Make DevInsight Work for You',
          description:
              'Choose the areas you care about most. Select as many as you like; you can adjust these later.',
          compact: compact,
        ),
        _sectionLabel(
          'Your interests',
          '${_interests.length} selected · select as many as you like',
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 620 ? 2 : 1;
            final itemWidth =
                (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _interestOptions
                  .map(
                    (option) => SizedBox(
                      width: itemWidth,
                      child: _interestCard(option),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotificationsStep({required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeading(
          eyebrow: 'Step 03 · Stay in the loop',
          title: 'Stay Informed, Your Way',
          description:
              'Choose which updates matter and how you would like to receive them.',
          compact: compact,
        ),
        _sectionLabel('Notification channels', 'Choose delivery methods'),
        const SizedBox(height: 12),
        _switchTile(
          title: 'Email notifications',
          subtitle: 'Receive important updates at ${_emailController.text}',
          icon: Icons.mail_outline_rounded,
          value: _emailNotifications,
          onChanged: (value) => setState(() => _emailNotifications = value),
        ),
        const SizedBox(height: 10),
        _pushChannelTile(),
        const SizedBox(height: 26),
        _sectionLabel('What you hear about', 'Manage alert categories'),
        const SizedBox(height: 12),
        ..._notificationCategories.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _switchTile(
              title: entry.key,
              subtitle: _categoryDescription(entry.key),
              icon: _categoryIcon(entry.key),
              value: entry.value,
              onChanged: (value) =>
                  setState(() => _notificationCategories[entry.key] = value),
              dense: true,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.edit_notifications_outlined,
              size: 17,
              color: AppColors.azureBlue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Notification choices can be changed later in account settings when account settings are connected.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.authSecondaryText,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionLabel(String title, String helper) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.authText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                helper,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.authSecondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _responsivePair({
    required bool compact,
    required Widget first,
    required Widget second,
  }) {
    if (compact) {
      return Column(children: [first, const SizedBox(height: 16), second]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 16),
        Expanded(child: second),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.authText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.plusJakartaSans(
            color: readOnly ? AppColors.authSecondaryText : AppColors.authText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            filled: true,
            fillColor: readOnly ? const Color(0xFFF2F6FC) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            hintStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF9AA8BE),
              fontSize: 13,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0xFFDCE7F5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: AppColors.royalBlue,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _roleCard({
    required String role,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _role == role;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() {
        _role = role;
        _roleError = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F5FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.royalBlue : const Color(0xFFDCE7F5),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.royalBlue.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? Colors.white : const Color(0xFFF3F6FB),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: selected
                    ? AppColors.royalBlue
                    : AppColors.authSecondaryText,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.authText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.authSecondaryText,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.royalBlue : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.royalBlue
                      : const Color(0xFFC9D4E3),
                  width: 1.4,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _interestCard(_SelectionOption option) {
    final selected = _interests.contains(option.title);
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () => setState(() {
        if (selected) {
          _interests.remove(option.title);
        } else {
          _interests.add(option.title);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 82),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F5FF) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? AppColors.royalBlue : const Color(0xFFDCE7F5),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? Colors.white : const Color(0xFFF3F6FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                option.icon,
                size: 19,
                color: selected ? AppColors.royalBlue : AppColors.azureBlue,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    option.title,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.authText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.authSecondaryText,
                      fontSize: 10.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 19,
              color: selected ? AppColors.royalBlue : const Color(0xFFC9D4E3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool dense = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: dense ? 9 : 12),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFF5F8FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE7F5)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.azureBlue, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.authText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.authSecondaryText,
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.royalBlue,
          ),
        ],
      ),
    );
  }

  Widget _pushChannelTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4EAF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFF9AA8BE),
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Browser / push notifications',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.authText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Preference only · push delivery is not configured',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.authSecondaryText,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch.adaptive(
            value: _pushNotifications,
            onChanged: _isSaving
                ? null
                : (value) => setState(() => _pushNotifications = value),
            activeThumbColor: AppColors.royalBlue,
          ),
        ],
      ),
    );
  }

  String _categoryDescription(String category) => switch (category) {
    'Critical Risk Alerts' => 'Important delivery and project risk changes.',
    'Project Updates' => 'Milestones, health changes, and status updates.',
    'Issue Assignments' => 'Work assigned or updated for you.',
    'AI Recommendations' => 'New suggested actions and insights.',
    _ => 'Meaningful activity across your projects.',
  };

  IconData _categoryIcon(String category) => switch (category) {
    'Critical Risk Alerts' => Icons.warning_amber_rounded,
    'Project Updates' => Icons.sync_alt_rounded,
    'Issue Assignments' => Icons.assignment_ind_outlined,
    'AI Recommendations' => Icons.auto_awesome_outlined,
    _ => Icons.bolt_rounded,
  };

  Widget _buildActions({required bool compact}) {
    final firstStep = _step == 0;
    final lastStep = _step == 2;
    return Row(
      children: [
        if (!firstStep)
          OutlinedButton.icon(
            onPressed: _isSaving || _isLoadingState ? null : _goBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 17),
            label: const Text('Back'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.authText,
              side: const BorderSide(color: Color(0xFFDCE7F5)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              textStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          )
        else
          const SizedBox.shrink(),
        const Spacer(),
        SizedBox(
          width: compact ? 190 : 220,
          height: 50,
          child: FilledButton(
            onPressed: _isSaving || _isLoadingState
                ? null
                : lastStep
                ? _completeOnboarding
                : _goNext,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.royalBlue,
              foregroundColor: Colors.white,
              elevation: 3,
              shadowColor: AppColors.royalBlue.withValues(alpha: 0.28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _isSaving
                  ? [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(lastStep ? 'Saving setup…' : 'Saving…'),
                        ),
                      ),
                    ]
                  : [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(lastStep ? 'Complete Setup' : 'Next'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        lastStep
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        size: 17,
                      ),
                    ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrototypeNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5EBF4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: AppColors.azureBlue,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Your onboarding choices are saved to your account. Email and push delivery are not configured by this setup.',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.authSecondaryText,
                fontSize: 10.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionOption {
  const _SelectionOption(this.title, this.description, this.icon);

  final String title;
  final String description;
  final IconData icon;
}
