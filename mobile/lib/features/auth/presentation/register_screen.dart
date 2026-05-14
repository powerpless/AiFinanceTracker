import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/glow_card.dart';
import '../auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() => setState(() {});

  @override
  void dispose() {
    _passwordCtrl.removeListener(_onPasswordChanged);
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  String? _validatePassword(String? v) {
    if (v == null || v.length < 8) return 'Минимум 8 символов';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Нужна заглавная буква';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Нужна строчная буква';
    if (!RegExp(r'\d').hasMatch(v)) return 'Нужна цифра';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final ok = await ref.read(authControllerProvider.notifier).register(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
          confirmPassword: _confirmCtrl.text,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
        );
    if (mounted) {
      setState(() => _submitting = false);
      if (ok) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = ref.watch(
      authControllerProvider.select((s) => s.errorMessage),
    );
    final pw = _passwordCtrl.text;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _RegAmbientGlow()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AuthHeader(
                        onBack: _submitting ? null : () => context.pop(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Создание аккаунта',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Начни отслеживать расходы и получать AI-советы',
                        style: TextStyle(
                          color: AppColors.textMid,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SectionLabel(
                              icon: Icons.badge_outlined,
                              text: 'Профиль',
                            ),
                            const SizedBox(height: 10),
                            GlowCard(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 18, 16, 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _LabeledField(
                                          label: 'Имя',
                                          child: TextFormField(
                                            controller: _firstNameCtrl,
                                            textCapitalization:
                                                TextCapitalization.words,
                                            textInputAction:
                                                TextInputAction.next,
                                            decoration: const InputDecoration(
                                              hintText: 'Иван',
                                            ),
                                            validator: (v) =>
                                                (v == null || v.trim().isEmpty)
                                                    ? 'Введите имя'
                                                    : null,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _LabeledField(
                                          label: 'Фамилия',
                                          child: TextFormField(
                                            controller: _lastNameCtrl,
                                            textCapitalization:
                                                TextCapitalization.words,
                                            textInputAction:
                                                TextInputAction.next,
                                            decoration: const InputDecoration(
                                              hintText: 'Иванов',
                                            ),
                                            validator: (v) =>
                                                (v == null || v.trim().isEmpty)
                                                    ? 'Введите фамилию'
                                                    : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            _SectionLabel(
                              icon: Icons.shield_outlined,
                              text: 'Доступ',
                            ),
                            const SizedBox(height: 10),
                            GlowCard(
                              variant: GlowCardVariant.hero,
                              padding: const EdgeInsets.fromLTRB(
                                  16, 18, 16, 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _LabeledField(
                                    label: 'Логин',
                                    child: TextFormField(
                                      controller: _usernameCtrl,
                                      autofillHints: const [
                                        AutofillHints.newUsername
                                      ],
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        hintText: 'username',
                                        prefixIcon:
                                            Icon(Icons.alternate_email),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().length < 3)
                                              ? 'Минимум 3 символа'
                                              : null,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _LabeledField(
                                    label: 'Пароль',
                                    child: TextFormField(
                                      controller: _passwordCtrl,
                                      autofillHints: const [
                                        AutofillHints.newPassword
                                      ],
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        hintText: '••••••••',
                                        prefixIcon:
                                            const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          splashRadius: 18,
                                          onPressed: () => setState(() =>
                                              _obscurePassword =
                                                  !_obscurePassword),
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            size: 18,
                                            color: AppColors.textDim,
                                          ),
                                        ),
                                      ),
                                      validator: _validatePassword,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _PasswordStrength(password: pw),
                                  const SizedBox(height: 16),
                                  _LabeledField(
                                    label: 'Повторите пароль',
                                    child: TextFormField(
                                      controller: _confirmCtrl,
                                      obscureText: _obscureConfirm,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _submit(),
                                      decoration: InputDecoration(
                                        hintText: '••••••••',
                                        prefixIcon: const Icon(
                                            Icons.lock_person_outlined),
                                        suffixIcon: IconButton(
                                          splashRadius: 18,
                                          onPressed: () => setState(() =>
                                              _obscureConfirm =
                                                  !_obscureConfirm),
                                          icon: Icon(
                                            _obscureConfirm
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            size: 18,
                                            color: AppColors.textDim,
                                          ),
                                        ),
                                      ),
                                      validator: (v) => v != _passwordCtrl.text
                                          ? 'Пароли не совпадают'
                                          : null,
                                    ),
                                  ),
                                  if (errorMessage != null) ...[
                                    const SizedBox(height: 14),
                                    _ErrorBanner(message: errorMessage),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            _PrimaryButton(
                              label: 'Зарегистрироваться',
                              loading: _submitting,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: 14),
                            _AgreementText(),
                            const SizedBox(height: 18),
                            _BottomPrompt(
                              text: 'Уже есть аккаунт?',
                              actionLabel: 'Войти',
                              onTap: _submitting ? null : () => context.pop(),
                            ),
                            const SizedBox(height: 8),
                          ],
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
    );
  }
}

class _AuthHeader extends StatelessWidget {
  final VoidCallback? onBack;
  const _AuthHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconButtonBox(icon: Icons.arrow_back, onTap: onBack),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accentSofter,
            border: Border.all(color: AppColors.accentHair),
            borderRadius: AppRadius.rPill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.auto_awesome, size: 12, color: AppColors.accentBright),
              SizedBox(width: 6),
              Text(
                'FinTracker',
                style: TextStyle(
                  color: AppColors.accentBright,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        const SizedBox(width: 36),
      ],
    );
  }
}

class _IconButtonBox extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _IconButtonBox({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.rMd,
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.bgRaised,
            border: Border.all(color: AppColors.hairline),
            borderRadius: AppRadius.rMd,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: AppColors.textMid),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textDim),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMid,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  final String password;
  const _PasswordStrength({required this.password});

  @override
  Widget build(BuildContext context) {
    final rules = <_Rule>[
      _Rule('8+ симв.', password.length >= 8),
      _Rule('A-Z', RegExp(r'[A-Z]').hasMatch(password)),
      _Rule('a-z', RegExp(r'[a-z]').hasMatch(password)),
      _Rule('0-9', RegExp(r'\d').hasMatch(password)),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: rules.map((r) => _StrengthChip(rule: r)).toList(),
    );
  }
}

class _Rule {
  final String label;
  final bool ok;
  const _Rule(this.label, this.ok);
}

class _StrengthChip extends StatelessWidget {
  final _Rule rule;
  const _StrengthChip({required this.rule});

  @override
  Widget build(BuildContext context) {
    final ok = rule.ok;
    final fg = ok ? AppColors.mint : AppColors.textDim;
    final bg = ok ? AppColors.mintSoft : AppColors.bgSunken;
    final border = ok ? AppColors.mintHair : AppColors.hairline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: AppRadius.rPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 11,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            rule.label,
            style: TextStyle(
              color: fg,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgreementText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        'Создавая аккаунт, вы соглашаетесь с условиями использования и политикой обработки данных.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textDim,
          fontSize: 11,
          height: 1.45,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.coralSoft,
        border: Border.all(color: AppColors.coralHair),
        borderRadius: AppRadius.rMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: 16,
            color: AppColors.coral,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.coral,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.rMd,
        boxShadow: AppShadows.fab,
      ),
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.onAccent,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
      ),
    );
  }
}

class _BottomPrompt extends StatelessWidget {
  final String text;
  final String actionLabel;
  final VoidCallback? onTap;

  const _BottomPrompt({
    required this.text,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: const TextStyle(color: AppColors.textDim, fontSize: 13),
        ),
        const SizedBox(width: 6),
        InkWell(
          borderRadius: AppRadius.rSm,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              actionLabel,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RegAmbientGlow extends StatelessWidget {
  const _RegAmbientGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -180,
            left: -80,
            child: Container(
              width: 360,
              height: 360,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.accentSoft, Color(0x00000000)],
                  stops: [0.0, 0.7],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            right: -120,
            child: Container(
              width: 380,
              height: 380,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.accentSofter, Color(0x00000000)],
                  stops: [0.0, 0.75],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
