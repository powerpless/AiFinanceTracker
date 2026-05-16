import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/format.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_bottom_nav.dart';
import '../../../widgets/glow_card.dart';
import '../../auth/auth_providers.dart';
import '../settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Local (non-persistent) preferences. Persisted versions can be wired
  // through providers in a follow-up — backend hasn't exposed them yet.
  bool _notifDaily = true;
  bool _notifLimit = true;
  bool _notifBig = false;
  bool _faceId = false;
  bool _appLock = false;
  bool _hideAmounts = false;
  int _accentHue = 295;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final currency = ref.watch(currencyProvider);
    final budget = ref.watch(monthlyBudgetProvider);
    final aiTips = ref.watch(aiSavingsTipsEnabledProvider);
    final aiForecast = ref.watch(aiTrendForecastEnabledProvider);
    final aiAnomaly = ref.watch(aiAnomalyEnabledProvider);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: _Header()),
          SliverToBoxAdapter(child: _ProfileCard(username: auth.username)),
          SliverToBoxAdapter(
            child: _Section(
              label: 'ВАЛЮТА',
              footer:
                  'Выбор валюты влияет только на отображение. Транзакции хранятся в числовом виде без конвертации.',
              children: [
                for (final c in Currency.values)
                  _CurrencyRow(
                    currency: c,
                    selected: currency == c,
                    onTap: () => ref
                        .read(currencyProvider.notifier)
                        .setCurrency(c),
                    last: c == Currency.values.last,
                  ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              label: 'AI · ML-СЕРВИС',
              children: [
                _ToggleRow(
                  icon: Icons.lightbulb_outline,
                  iconColor: AppColors.mint,
                  label: 'Советы по экономии',
                  sub: 'Подсказки, как сократить траты',
                  value: aiTips,
                  onChanged: (v) => ref
                      .read(aiSavingsTipsEnabledProvider.notifier)
                      .set(v),
                ),
                _ToggleRow(
                  icon: Icons.trending_up,
                  iconColor: AppColors.accent,
                  label: 'Прогнозы трендов',
                  sub: 'Линейная регрессия по категориям',
                  value: aiForecast,
                  onChanged: (v) => ref
                      .read(aiTrendForecastEnabledProvider.notifier)
                      .set(v),
                ),
                _ToggleRow(
                  icon: Icons.warning_amber_outlined,
                  iconColor: AppColors.coral,
                  label: 'Аномалии в тратах',
                  sub: 'Уведомлять при необычно крупных операциях',
                  value: aiAnomaly,
                  onChanged: (v) =>
                      ref.read(aiAnomalyEnabledProvider.notifier).set(v),
                  last: true,
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              label: 'БЮДЖЕТ',
              children: [
                _BudgetRow(
                  value: budget,
                  symbol: currency.symbol,
                  onChanged: (v) =>
                      ref.read(monthlyBudgetProvider.notifier).setBudget(v),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              label: 'УВЕДОМЛЕНИЯ',
              children: [
                _ToggleRow(
                  icon: Icons.notifications_outlined,
                  label: 'Дневная сводка',
                  sub: 'Каждый день в 21:00',
                  value: _notifDaily,
                  onChanged: (v) => setState(() => _notifDaily = v),
                ),
                _ToggleRow(
                  icon: Icons.shield_outlined,
                  label: 'Превышение лимита',
                  value: _notifLimit,
                  onChanged: (v) => setState(() => _notifLimit = v),
                ),
                _ToggleRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Крупные операции',
                  sub: 'От 5 000 ₸',
                  value: _notifBig,
                  onChanged: (v) => setState(() => _notifBig = v),
                  last: true,
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              label: 'ВНЕШНИЙ ВИД',
              footer:
                  'Динамическая смена темы появится в одном из следующих обновлений.',
              children: [
                _AccentPicker(
                  current: _accentHue,
                  onPick: (h) => setState(() => _accentHue = h),
                ),
                _StaticRow(
                  icon: Icons.dark_mode_outlined,
                  label: 'Тёмная тема',
                  trailing: const _RowValue(text: 'Всегда'),
                  last: true,
                  onTap: null,
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              label: 'БЕЗОПАСНОСТЬ',
              children: [
                _ToggleRow(
                  icon: Icons.fingerprint,
                  iconColor: AppColors.accent,
                  label: 'Face ID / Touch ID',
                  sub: 'Вход без пароля',
                  value: _faceId,
                  onChanged: (v) => setState(() => _faceId = v),
                ),
                _ToggleRow(
                  icon: Icons.lock_outline,
                  label: 'Код-пароль',
                  sub: 'Запрашивать при открытии',
                  value: _appLock,
                  onChanged: (v) => setState(() => _appLock = v),
                ),
                _ToggleRow(
                  icon: Icons.visibility_off_outlined,
                  label: 'Скрывать суммы на главной',
                  value: _hideAmounts,
                  onChanged: (v) => setState(() => _hideAmounts = v),
                  last: true,
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              label: 'ДАННЫЕ',
              children: [
                _StaticRow(
                  icon: Icons.file_upload_outlined,
                  label: 'Экспорт CSV',
                  sub: 'Все операции за всё время',
                  trailing: const _Chevron(),
                  onTap: () => _confirm(
                    title: 'Экспортировать данные?',
                    body:
                        'Будет создан CSV-файл со всеми операциями. Эта функция появится в одном из ближайших обновлений.',
                    confirmLabel: 'Понятно',
                    onConfirm: () => _toast('Экспорт пока недоступен'),
                  ),
                ),
                _StaticRow(
                  icon: Icons.cloud_upload_outlined,
                  label: 'Резервная копия',
                  sub: 'Облачные бэкапы — скоро',
                  trailing: const _Chevron(),
                  onTap: () =>
                      _toast('Облачное резервирование появится позже'),
                ),
                _StaticRow(
                  icon: Icons.delete_outline,
                  iconColor: AppColors.coral,
                  label: 'Сбросить все данные',
                  danger: true,
                  trailing: const _Chevron(),
                  last: true,
                  onTap: () => _confirm(
                    title: 'Удалить все данные?',
                    body:
                        'Все операции, категории, лимиты и ML-модели будут стёрты. Это действие нельзя отменить.',
                    confirmLabel: 'Удалить',
                    danger: true,
                    onConfirm: () =>
                        _toast('Сброс пока недоступен — обратитесь в поддержку'),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              label: 'О ПРИЛОЖЕНИИ',
              children: [
                _StaticRow(
                  icon: Icons.info_outline,
                  label: 'Версия',
                  trailing: const _RowValue(text: '1.0.0 (1)'),
                  onTap: null,
                ),
                _StaticRow(
                  icon: Icons.help_outline,
                  label: 'Поддержка',
                  trailing: const _Chevron(),
                  onTap: () => _toast('mpetrov@fintracker.dev'),
                ),
                _StaticRow(
                  icon: Icons.description_outlined,
                  label: 'Конфиденциальность',
                  trailing: const _Chevron(),
                  last: true,
                  onTap: () => _toast('Документ откроется в обновлении'),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                18,
                AppSpacing.screen,
                0,
              ),
              child: _LogoutButton(
                onTap: () => _confirm(
                  title: 'Выйти из аккаунта?',
                  body: 'Локальные данные сохранятся. Войдите снова, чтобы продолжить.',
                  confirmLabel: 'Выйти',
                  onConfirm: () async {
                    await ref.read(authControllerProvider.notifier).logout();
                  },
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: kBottomNavReservedSpace),
          ),
        ],
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    required VoidCallback onConfirm,
    bool danger = false,
  }) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ConfirmSheet(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        danger: danger,
      ),
    );
    if (ok == true) onConfirm();
  }
}

// ──────────────────────────── HEADER ────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 8, AppSpacing.screen, 0),
      child: Row(
        children: const [
          Text(
            'Настройки',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────── PROFILE CARD ──────────────────────────

class _ProfileCard extends StatelessWidget {
  final String? username;
  const _ProfileCard({required this.username});

  String _initials(String? u) {
    if (u == null || u.isEmpty) return '·';
    final parts = u.trim().split(RegExp(r'[\s@._-]+'));
    return parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 10, AppSpacing.screen, 0),
      child: GlowCard(
        variant: GlowCardVariant.hero,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -60,
              right: -60,
              child: IgnorePointer(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [AppColors.accentSoft, Color(0x00000000)],
                      stops: [0.0, 0.7],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.accentHair),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(username),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (username == null || username!.isEmpty)
                            ? 'Гость'
                            : username!,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Локальный профиль',
                        style: TextStyle(
                          color: AppColors.textMid,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────── SECTION ─────────────────────────────

class _Section extends StatelessWidget {
  final String label;
  final List<Widget> children;
  final String? footer;

  const _Section({
    required this.label,
    required this.children,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 18, AppSpacing.screen, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 10.5,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: AppRadius.rCard,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.bgRaised,
                borderRadius: AppRadius.rCard,
                border: Border.all(color: AppColors.hairline),
              ),
              child: Column(children: children),
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                footer!,
                style: const TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────── ROW PRIMITIVES ────────────────────────

class _RowChrome extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool last;

  const _RowChrome({required this.child, this.onTap, this.last = false});

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          bottom: last
              ? BorderSide.none
              : const BorderSide(color: AppColors.hairlineSoft),
        ),
      ),
      child: child,
    );
    if (onTap == null) return container;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: container),
    );
  }
}

class _IconSlot extends StatelessWidget {
  final IconData icon;
  final Color? color;

  const _IconSlot({required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.bgSunken,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.hairline),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 15, color: color ?? AppColors.textMid),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.chevron_right, size: 16, color: AppColors.textFaint);
  }
}

class _RowValue extends StatelessWidget {
  final String text;
  const _RowValue({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: const TextStyle(color: AppColors.textDim, fontSize: 12.5),
        ),
        const SizedBox(width: 4),
        const _Chevron(),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.sub,
    this.iconColor,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return _RowChrome(
      last: last,
      child: Row(
        children: [
          _IconSlot(icon: icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13.5,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    sub!,
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.accent,
            inactiveThumbColor: AppColors.textMid,
            inactiveTrackColor: AppColors.bgSunken,
            trackOutlineColor:
                WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected)
                    ? AppColors.accent
                    : AppColors.hairline),
          ),
        ],
      ),
    );
  }
}

class _StaticRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String? sub;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final bool last;

  const _StaticRow({
    required this.icon,
    required this.label,
    this.iconColor,
    this.sub,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return _RowChrome(
      last: last,
      onTap: onTap,
      child: Row(
        children: [
          _IconSlot(icon: icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: danger ? AppColors.coral : AppColors.text,
                    fontSize: 13.5,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    sub!,
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// ─────────────────────── CURRENCY ROW ───────────────────────────

class _CurrencyRow extends StatelessWidget {
  final Currency currency;
  final bool selected;
  final VoidCallback onTap;
  final bool last;

  const _CurrencyRow({
    required this.currency,
    required this.selected,
    required this.onTap,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    return _RowChrome(
      last: last,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: selected ? AppColors.accentSoft : AppColors.bgSunken,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: selected ? AppColors.accentHair : AppColors.hairline,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              currency.code,
              style: TextStyle(
                color: selected ? AppColors.accent : AppColors.textMid,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currency.name} (${currency.symbol})',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  currency.code,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.accent : Colors.transparent,
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.hairline,
                width: 1.5,
              ),
              boxShadow: selected
                  ? const [
                      BoxShadow(color: AppColors.accentGlow, blurRadius: 10),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: selected
                ? const Icon(Icons.check, size: 11, color: AppColors.onAccent)
                : null,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── BUDGET ROW ─────────────────────────────

class _BudgetRow extends StatefulWidget {
  final double value;
  final String symbol;
  final ValueChanged<double> onChanged;

  const _BudgetRow({
    required this.value,
    required this.symbol,
    required this.onChanged,
  });

  @override
  State<_BudgetRow> createState() => _BudgetRowState();
}

class _BudgetRowState extends State<_BudgetRow> {
  bool _editing = false;
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.value.toStringAsFixed(0));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit() {
    final parsed = double.tryParse(_ctrl.text.replaceAll(',', '.'));
    if (parsed != null && parsed >= 0) {
      widget.onChanged(parsed);
    } else {
      _ctrl.text = widget.value.toStringAsFixed(0);
    }
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return _RowChrome(
      child: Row(
        children: [
          const _IconSlot(icon: Icons.adjust),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Месячный лимит',
                  style: TextStyle(color: AppColors.text, fontSize: 13.5),
                ),
                SizedBox(height: 1),
                Text(
                  'Лимит на все расходы',
                  style: TextStyle(color: AppColors.textDim, fontSize: 11.5),
                ),
              ],
            ),
          ),
          if (_editing)
            SizedBox(
              width: 110,
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                textAlign: TextAlign.right,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                onSubmitted: (_) => _commit(),
                onTapOutside: (_) => _commit(),
                style: const TextStyle(color: AppColors.text, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  filled: true,
                  fillColor: AppColors.bgSunken,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.accentHair),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.accentHair),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
            )
          else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _ctrl.text = widget.value.toStringAsFixed(0);
                  setState(() => _editing = true);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatMoney(widget.value, symbol: widget.symbol),
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.edit_outlined,
                        size: 12,
                        color: AppColors.textFaint,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────── ACCENT PICKER ──────────────────────────

class _AccentPicker extends StatelessWidget {
  final int current;
  final ValueChanged<int> onPick;

  const _AccentPicker({required this.current, required this.onPick});

  static const _swatches = <(int, String)>[
    (295, 'Лиловый'),
    (270, 'Сапфир'),
    (320, 'Магнолия'),
    (245, 'Индиго'),
  ];

  // Pre-computed OKLCH(0.74 0.08 hue) → sRGB for each swatch.
  static const _swatchColors = <int, Color>{
    295: AppColors.accent,
    270: Color(0xFFA9A4DE),
    320: Color(0xFFC09BD0),
    245: Color(0xFF9DAFE6),
  };

  @override
  Widget build(BuildContext context) {
    return _RowChrome(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Акцентный цвет',
            style: TextStyle(color: AppColors.text, fontSize: 13.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final (hue, name) in _swatches)
                Expanded(
                  child: _Swatch(
                    color: _swatchColors[hue] ?? AppColors.accent,
                    name: name,
                    active: hue == current,
                    onTap: () => onPick(hue),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final String name;
  final bool active;
  final VoidCallback onTap;

  const _Swatch({
    required this.color,
    required this.name,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: active ? AppColors.text : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 18,
                          ),
                        ]
                      : const [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 12,
                            spreadRadius: -6,
                            offset: Offset(0, 4),
                          ),
                        ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(
                  color: active ? AppColors.text : AppColors.textDim,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────── LOGOUT BUTTON ─────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rLg,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rLg,
            border: Border.all(color: AppColors.coralHair),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.logout, size: 16, color: AppColors.coral),
              SizedBox(width: 8),
              Text(
                'Выйти из аккаунта',
                style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────── CONFIRM SHEET ─────────────────────────

class _ConfirmSheet extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final bool danger;

  const _ConfirmSheet({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.danger,
  });

  @override
  Widget build(BuildContext context) {
    final accent = danger ? AppColors.coral : AppColors.accent;
    final hair = danger ? AppColors.coralHair : AppColors.accentHair;
    final glow = danger ? AppColors.coralHair : AppColors.accentGlow;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 12, right: 12, bottom: 46 + bottomInset),
      child: GlowCard(
        variant: GlowCardVariant.hero,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        border: Border.all(color: hair),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: const TextStyle(
                color: AppColors.textMid,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.hairline),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.rMd,
                      ),
                    ),
                    child: const Text(
                      'Отмена',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: AppColors.onAccent,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.rMd,
                      ),
                    ).copyWith(
                      shadowColor: WidgetStateProperty.all(glow),
                      elevation: WidgetStateProperty.all(0),
                    ),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
