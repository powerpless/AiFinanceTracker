import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glow_card.dart';
import '../../categories/category_providers.dart';
import '../../categories/data/category_models.dart';
import '../../dashboard/dashboard_providers.dart';
import '../../home/utils/category_icons.dart';
import '../../settings/settings_providers.dart';
import '../data/transaction_models.dart';
import '../transaction_providers.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  final CategoryType? initialType;

  const TransactionFormScreen({
    super.key,
    this.initialCategoryId,
    this.initialType,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState
    extends ConsumerState<TransactionFormScreen> {
  late CategoryType _type;
  String _amountStr = '';
  String? _selectedCategoryId;
  DateTime _date = DateTime.now();
  String _description = '';
  bool _submitting = false;
  bool _saved = false;
  bool _initialCategoryApplied = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? CategoryType.expense;
  }

  double get _amountValue {
    if (_amountStr.isEmpty) return 0;
    return double.tryParse(_amountStr) ?? 0;
  }

  bool get _canSave => _amountValue > 0 && _selectedCategoryId != null;

  void _appendKey(String key) {
    setState(() {
      switch (key) {
        case 'back':
          if (_amountStr.isNotEmpty) {
            _amountStr = _amountStr.substring(0, _amountStr.length - 1);
          }
          return;
        case '.':
          if (_amountStr.contains('.')) return;
          _amountStr = _amountStr.isEmpty ? '0.' : '$_amountStr.';
          return;
        default:
          final next = _amountStr + key;
          final parts = next.split('.');
          final whole = parts[0];
          final frac = parts.length > 1 ? parts[1] : null;
          if (whole.length > 9 && !next.contains('.')) return;
          if (frac != null && frac.length > 2) return;
          // Strip leading zeros in whole part unless followed by decimal.
          if (!next.contains('.') &&
              next.length > 1 &&
              next.startsWith('0')) {
            _amountStr = next.replaceFirst(RegExp(r'^0+'), '');
            if (_amountStr.isEmpty) _amountStr = '0';
          } else {
            _amountStr = next;
          }
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _DatePickerSheet(initialDate: _date),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _editNote() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _NoteSheet(initialValue: _description),
    );
    if (result != null) {
      setState(() => _description = result);
    }
  }

  Future<void> _createCategory() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _CategoryEditorSheet(title: 'Новая категория'),
    );
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty || !mounted) return;
    try {
      final created =
          await ref.read(categoryApiProvider).create(trimmed, _type);
      ref.invalidate(categoriesProvider);
      if (!mounted) return;
      setState(() => _selectedCategoryId = created.id);
    } on DioException catch (e) {
      if (!mounted) return;
      final apiErr = e.error;
      final msg = apiErr is ApiException
          ? apiErr.message
          : 'Не удалось создать категорию';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _showCategoryActions(Category category) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryActionsSheet(category: category),
    );
    if (!mounted || action == null) return;
    if (action == 'rename') await _renameCategory(category);
    if (action == 'delete') await _deleteCategory(category);
  }

  Future<void> _renameCategory(Category category) async {
    final newName = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CategoryEditorSheet(
        title: 'Переименовать',
        initialValue: category.name,
      ),
    );
    final trimmed = newName?.trim();
    if (trimmed == null ||
        trimmed.isEmpty ||
        trimmed == category.name ||
        !mounted) {
      return;
    }
    try {
      await ref
          .read(categoryApiProvider)
          .update(category.id, trimmed, category.type);
      ref.invalidate(categoriesProvider);
    } on DioException catch (e) {
      if (!mounted) return;
      final apiErr = e.error;
      final msg = apiErr is ApiException
          ? apiErr.message
          : 'Не удалось переименовать';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DeleteConfirmSheet(name: category.name),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(categoryApiProvider).delete(category.id);
      ref.invalidate(categoriesProvider);
      if (!mounted) return;
      if (_selectedCategoryId == category.id) {
        setState(() => _selectedCategoryId = null);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final apiErr = e.error;
      final msg = apiErr is ApiException
          ? apiErr.message
          : 'Не удалось удалить категорию';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _submit() async {
    if (!_canSave || _submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(transactionApiProvider).create(
            TransactionCreateRequest(
              categoryId: _selectedCategoryId!,
              amount: _amountValue,
              operationDate: _date,
              description: _description.trim().isEmpty ? null : _description,
            ),
          );
      ref.invalidate(transactionsProvider);
      ref.invalidate(dashboardSummaryProvider);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _saved = true;
      });
      await Future.delayed(const Duration(milliseconds: 950));
      if (!mounted) return;
      context.pop();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final apiErr = e.error;
      final msg =
          apiErr is ApiException ? apiErr.message : 'Не удалось сохранить';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final symbol = ref.watch(currencyProvider).symbol;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientGlow()),
          SafeArea(
            child: Column(
              children: [
                _Header(onBack: () => context.pop()),
                const SizedBox(height: 8),
                _TypeSegmented(
                  value: _type,
                  onChanged: (v) => setState(() {
                    _type = v;
                    _selectedCategoryId = null;
                  }),
                ),
                const SizedBox(height: 10),
                _AmountHero(
                  amountStr: _amountStr,
                  type: _type,
                  symbol: symbol,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: [
                        _CategoryGrid(
                          categoriesAsync: categoriesAsync,
                          type: _type,
                          selectedId: _selectedCategoryId,
                          onSelected: (id) =>
                              setState(() => _selectedCategoryId = id),
                          onCreate: _createCategory,
                          onCategoryLongPress: _showCategoryActions,
                          onCategoriesLoaded: (list) {
                            if (_initialCategoryApplied) return;
                            _initialCategoryApplied = true;
                            final initial =
                                widget.initialCategoryId == null
                                    ? null
                                    : list.firstWhere(
                                        (c) =>
                                            c.id == widget.initialCategoryId,
                                        orElse: () => list.first,
                                      );
                            if (initial != null) {
                              WidgetsBinding.instance
                                  .addPostFrameCallback((_) {
                                if (!mounted) return;
                                setState(() {
                                  _selectedCategoryId = initial.id;
                                  _type = initial.type;
                                });
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        _MetaRows(
                          date: _date,
                          description: _description,
                          onDateTap: _pickDate,
                          onNoteTap: _editNote,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                _Numpad(
                  onKey: _appendKey,
                  onSave: _submit,
                  canSave: _canSave && !_submitting,
                  submitting: _submitting,
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          if (_saved) const _SuccessOverlay(),
        ],
      ),
    );
  }
}

// ─────────────────────── ambient glow ──────────────────────

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 360,
                height: 240,
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
        ],
      ),
    );
  }
}

// ───────────────────────── HEADER ──────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 6, AppSpacing.screen, 0),
      child: Row(
        children: [
          _SquareIconBtn(icon: Icons.arrow_back, onTap: onBack),
          const Expanded(
            child: Center(
              child: Text(
                'Новая транзакция',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _SquareIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rMd,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rMd,
            border: Border.all(color: AppColors.hairline),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppColors.textMid),
        ),
      ),
    );
  }
}

// ─────────────────────── TYPE SEG ──────────────────────────

class _TypeSegmented extends StatelessWidget {
  final CategoryType value;
  final ValueChanged<CategoryType> onChanged;

  const _TypeSegmented({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.bgSunken,
          borderRadius: AppRadius.rLg,
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TypeBtn(
                label: 'Расход',
                icon: Icons.arrow_upward,
                active: value == CategoryType.expense,
                onTap: () => onChanged(CategoryType.expense),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _TypeBtn(
                label: 'Доход',
                icon: Icons.arrow_downward,
                active: value == CategoryType.income,
                onTap: () => onChanged(CategoryType.income),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TypeBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.bgRaised : Colors.transparent,
      borderRadius: AppRadius.rSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rSm,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rSm,
            border: Border.all(
              color: active ? AppColors.accentHair : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: active ? AppColors.accent : AppColors.textDim,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                  color: active ? AppColors.text : AppColors.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────── AMOUNT HERO ─────────────────────────

class _AmountHero extends StatelessWidget {
  final String amountStr;
  final CategoryType type;
  final String symbol;

  const _AmountHero({
    required this.amountStr,
    required this.type,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = type == CategoryType.expense;
    final sign = isExpense ? '−' : '+';
    final hasAmount = amountStr.isNotEmpty;
    final signColor = hasAmount
        ? (isExpense ? AppColors.coral : AppColors.mint)
        : AppColors.textFaint;

    final parts = amountStr.split('.');
    final wholeRaw = parts[0].isEmpty ? '0' : parts[0];
    final wholeFormatted = NumberFormat.decimalPattern('ru_RU').format(
      int.tryParse(wholeRaw) ?? 0,
    );
    final frac = parts.length > 1 ? parts[1] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: GlowCard(
        variant: GlowCardVariant.hero,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -60,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 220,
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
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'СУММА',
                  style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sign,
                        style: TextStyle(
                          color: signColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        wholeFormatted,
                        style: TextStyle(
                          color: hasAmount
                              ? AppColors.text
                              : AppColors.textFaint,
                          fontSize: 48,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -1.6,
                          height: 1,
                        ),
                      ),
                      if (frac != null)
                        Text(
                          '.${frac.padRight(2, '0').substring(0, frac.length.clamp(1, 2))}',
                          style: TextStyle(
                            color: hasAmount
                                ? AppColors.text.withValues(alpha: 0.7)
                                : AppColors.textFaint,
                            fontSize: 32,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          symbol,
                          style: const TextStyle(
                            color: AppColors.textMid,
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedOpacity(
                  opacity: hasAmount ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: const Text(
                    'Введите сумму с клавиатуры ниже',
                    style: TextStyle(
                      color: AppColors.textFaint,
                      fontSize: 11,
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

// ───────────────────── CATEGORY GRID ───────────────────────

class _CategoryGrid extends StatelessWidget {
  final AsyncValue<List<Category>> categoriesAsync;
  final CategoryType type;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final ValueChanged<List<Category>> onCategoriesLoaded;
  final VoidCallback onCreate;
  final ValueChanged<Category> onCategoryLongPress;

  const _CategoryGrid({
    required this.categoriesAsync,
    required this.type,
    required this.selectedId,
    required this.onSelected,
    required this.onCategoriesLoaded,
    required this.onCreate,
    required this.onCategoryLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Text(
              'КАТЕГОРИЯ',
              style: TextStyle(
                color: AppColors.textDim,
                fontSize: 11,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          categoriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Ошибка загрузки: $e',
                style: const TextStyle(color: AppColors.coral),
              ),
            ),
            data: (allCategories) {
              onCategoriesLoaded(allCategories);
              final filtered =
                  allCategories.where((c) => c.type == type).toList();
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length + 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, i) {
                  if (i == filtered.length) {
                    return _AddCategoryTile(onTap: onCreate);
                  }
                  final c = filtered[i];
                  final canEdit = !c.systemCategory;
                  return _CategoryTile(
                    category: c,
                    active: c.id == selectedId,
                    onTap: () => onSelected(c.id),
                    onLongPress:
                        canEdit ? () => onCategoryLongPress(c) : null,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _CategoryTile({
    required this.category,
    required this.active,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.accentSoft : AppColors.bgRaised,
      borderRadius: AppRadius.rMd,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: AppRadius.rMd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rMd,
            border: Border.all(
              color: active ? AppColors.accent : AppColors.hairline,
            ),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: AppColors.accentGlow,
                      blurRadius: 22,
                      spreadRadius: -12,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                iconForCategory(category.name),
                size: 20,
                color: active ? AppColors.accent : AppColors.textMid,
              ),
              const SizedBox(height: 4),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  color: active ? AppColors.text : AppColors.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCategoryTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCategoryTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgRaised,
      borderRadius: AppRadius.rMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rMd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rMd,
            border: Border.all(
              color: AppColors.accentHair,
              style: BorderStyle.solid,
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 20, color: AppColors.accent),
              SizedBox(height: 4),
              Text(
                'Новая',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, color: AppColors.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────── CATEGORY EDITOR / ACTIONS / DELETE ────────────

class _CategoryEditorSheet extends StatefulWidget {
  final String title;
  final String initialValue;

  const _CategoryEditorSheet({
    required this.title,
    this.initialValue = '',
  });

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _ctrl.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(left: 12, right: 12, bottom: 46 + bottomInset),
      child: GlowCard(
        variant: GlowCardVariant.hero,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 36),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.rSm,
                    ),
                  ),
                  child: const Text(
                    'Готово',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLength: 100,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(color: AppColors.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Например: Книги',
                hintStyle: const TextStyle(color: AppColors.textFaint),
                counterText: '',
                filled: true,
                fillColor: AppColors.bgSunken,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.hairline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.accent,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryActionsSheet extends StatelessWidget {
  final Category category;

  const _CategoryActionsSheet({required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 46),
      child: GlowCard(
        variant: GlowCardVariant.hero,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  iconForCategory(category.name),
                  size: 18,
                  color: AppColors.textMid,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ActionRow(
              icon: Icons.edit_outlined,
              label: 'Переименовать',
              color: AppColors.text,
              onTap: () => Navigator.of(context).pop('rename'),
            ),
            const SizedBox(height: 6),
            _ActionRow(
              icon: Icons.delete_outline,
              label: 'Удалить',
              color: AppColors.coral,
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgSunken,
      borderRadius: AppRadius.rSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rSm,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rSm,
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 13.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteConfirmSheet extends StatelessWidget {
  final String name;

  const _DeleteConfirmSheet({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 46),
      child: GlowCard(
        variant: GlowCardVariant.hero,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Удалить категорию?',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '«$name» исчезнет из списка. Транзакции с этой категорией будут заблокированы сервером, если они есть.',
              style: const TextStyle(
                color: AppColors.textMid,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
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
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.rMd,
                      ),
                    ),
                    child: const Text('Удалить'),
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

// ───────────────────────── META ROWS ───────────────────────

class _MetaRows extends StatelessWidget {
  final DateTime date;
  final String description;
  final VoidCallback onDateTap;
  final VoidCallback onNoteTap;

  const _MetaRows({
    required this.date,
    required this.description,
    required this.onDateTap,
    required this.onNoteTap,
  });

  static const _monthsGen = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  String _dateLabel() {
    final today = DateTime.now();
    final isSameDay = today.year == date.year &&
        today.month == date.month &&
        today.day == date.day;
    final yesterday = today.subtract(const Duration(days: 1));
    final isYesterday = yesterday.year == date.year &&
        yesterday.month == date.month &&
        yesterday.day == date.day;
    if (isSameDay) return 'Сегодня';
    if (isYesterday) return 'Вчера';
    return '${date.day} ${_monthsGen[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: GlowCard(
        variant: GlowCardVariant.card,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _MetaRow(
              icon: Icons.calendar_today_outlined,
              trailing: const Text(
                'Изменить',
                style: TextStyle(color: AppColors.accent, fontSize: 12),
              ),
              onTap: onDateTap,
              divider: true,
              child: Text(
                _dateLabel(),
                style: const TextStyle(color: AppColors.text, fontSize: 13.5),
              ),
            ),
            _MetaRow(
              icon: Icons.notes_outlined,
              trailing: const Icon(
                Icons.edit_outlined,
                size: 14,
                color: AppColors.textMid,
              ),
              onTap: onNoteTap,
              divider: false,
              child: Text(
                description.isEmpty
                    ? 'Описание (необязательно)'
                    : description,
                style: TextStyle(
                  color:
                      description.isEmpty ? AppColors.textDim : AppColors.text,
                  fontSize: 13.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool divider;

  const _MetaRow({
    required this.icon,
    required this.child,
    required this.onTap,
    required this.divider,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: divider
                  ? const BorderSide(color: AppColors.hairlineSoft)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textMid),
              const SizedBox(width: 10),
              Expanded(child: child),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────── NUMPAD ─────────────────────────

class _Numpad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onSave;
  final bool canSave;
  final bool submitting;

  const _Numpad({
    required this.onKey,
    required this.onSave,
    required this.canSave,
    required this.submitting,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.bgRaised,
          borderRadius: AppRadius.rHero,
          border: Border.all(color: AppColors.hairline),
        ),
        child: SizedBox(
          height: 220,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Expanded(child: _digitRow(['1', '2', '3'])),
                    Expanded(child: _digitRow(['4', '5', '6'])),
                    Expanded(child: _digitRow(['7', '8', '9'])),
                    Expanded(child: _digitRow(['.', '0', 'back'])),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              SizedBox(
                width: 92,
                child: _SaveBtn(
                  enabled: canSave,
                  submitting: submitting,
                  onTap: onSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _digitRow(List<String> keys) {
    return Row(
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          Expanded(child: _NumKey(label: keys[i], onTap: () => onKey(keys[i]))),
          if (i < keys.length - 1) const SizedBox(width: 5),
        ],
      ],
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NumKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBack = label == 'back';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.rLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.rLg,
          splashColor: AppColors.accentSofter,
          highlightColor: AppColors.accentSofter,
          child: Container(
            alignment: Alignment.center,
            child: isBack
                ? const Icon(
                    Icons.backspace_outlined,
                    size: 20,
                    color: AppColors.textMid,
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SaveBtn extends StatelessWidget {
  final bool enabled;
  final bool submitting;
  final VoidCallback onTap;

  const _SaveBtn({
    required this.enabled,
    required this.submitting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgDecoration = enabled
        ? const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.accentBright, AppColors.accent],
            ),
            borderRadius: BorderRadius.all(Radius.circular(16)),
            boxShadow: AppShadows.fab,
          )
        : BoxDecoration(
            color: AppColors.bgSunken,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hairline),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: bgDecoration,
          alignment: Alignment.center,
          child: submitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.onAccent,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check,
                      size: 22,
                      color:
                          enabled ? AppColors.onAccent : AppColors.textFaint,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Сохранить',
                      style: TextStyle(
                        color:
                            enabled ? AppColors.onAccent : AppColors.textFaint,
                        fontSize: 13,
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

// ─────────────────────── DATE SHEET ────────────────────────

class _DatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  const _DatePickerSheet({required this.initialDate});

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late int _year;
  late int _month;
  late DateTime _selected;

  static const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  static const _monthsNom = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
    _selected = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
  }

  void _stepMonth(int delta) {
    setState(() {
      var m = _month + delta;
      var y = _year;
      if (m < 1) {
        m = 12;
        y -= 1;
      } else if (m > 12) {
        m = 1;
        y += 1;
      }
      _month = m;
      _year = y;
    });
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(_year, _month, 1);
    final startWeekday = (first.weekday + 6) % 7; // Monday = 0
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final cells = <int?>[
      for (var i = 0; i < startWeekday; i++) null,
      for (var d = 1; d <= daysInMonth; d++) d,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final today = DateTime.now();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 12, right: 12, bottom: 46 + bottomInset),
      child: GlowCard(
        variant: GlowCardVariant.hero,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _SmallSquareBtn(
                  icon: Icons.chevron_left,
                  onTap: () => _stepMonth(-1),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${_monthsNom[_month - 1]} $_year',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                _SmallSquareBtn(
                  icon: Icons.chevron_right,
                  onTap: () => _stepMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final wd in _weekdays)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        wd,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cells.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemBuilder: (context, i) {
                final d = cells[i];
                if (d == null) return const SizedBox.shrink();
                final cellDate = DateTime(_year, _month, d);
                final isSel = cellDate.year == _selected.year &&
                    cellDate.month == _selected.month &&
                    cellDate.day == _selected.day;
                final isToday = cellDate.year == today.year &&
                    cellDate.month == today.month &&
                    cellDate.day == today.day;
                return _DayCell(
                  day: d,
                  selected: isSel,
                  today: isToday,
                  onTap: () =>
                      setState(() => _selected = cellDate),
                );
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.hairline),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.rMd,
                      ),
                    ),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.rMd,
                      ),
                    ),
                    child: const Text('Выбрать'),
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

class _DayCell extends StatelessWidget {
  final int day;
  final bool selected;
  final bool today;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent : Colors.transparent,
      borderRadius: AppRadius.rSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rSm,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rSm,
            border: !selected && today
                ? Border.all(color: AppColors.accentHair)
                : null,
          ),
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              color: selected ? AppColors.onAccent : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallSquareBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallSquareBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rSm,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rSm,
            border: Border.all(color: AppColors.hairline),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 14, color: AppColors.textMid),
        ),
      ),
    );
  }
}

// ─────────────────────── NOTE SHEET ────────────────────────

class _NoteSheet extends StatefulWidget {
  final String initialValue;
  const _NoteSheet({required this.initialValue});

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(left: 12, right: 12, bottom: 46 + bottomInset),
      child: GlowCard(
        variant: GlowCardVariant.hero,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Описание',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_ctrl.text),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 36),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.rSm,
                    ),
                  ),
                  child: const Text(
                    'Готово',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLines: 3,
              minLines: 3,
              style: const TextStyle(color: AppColors.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Например: Концерт в Live Hall',
                hintStyle: const TextStyle(color: AppColors.textFaint),
                filled: true,
                fillColor: AppColors.bgSunken,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.hairline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.accent,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────── SUCCESS OVERLAY ──────────────────────

class _SuccessOverlay extends StatelessWidget {
  const _SuccessOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.bg.withValues(alpha: 0.55),
        child: Center(
          child: GlowCard(
            variant: GlowCardVariant.hero,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.mint, AppColors.mintHair],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mintHair,
                        blurRadius: 22,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 22,
                    color: AppColors.onAccent,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Транзакция сохранена',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
