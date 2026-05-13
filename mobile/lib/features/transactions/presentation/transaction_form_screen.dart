import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../categories/category_providers.dart';
import '../../categories/data/category_models.dart';
import '../../dashboard/dashboard_providers.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  late CategoryType _type;
  Category? _selectedCategory;
  DateTime _date = DateTime.now();
  bool _submitting = false;
  bool _categoryPreselected = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? CategoryType.expense;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите категорию')),
      );
      return;
    }
    setState(() => _submitting = true);

    try {
      final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
      await ref.read(transactionApiProvider).create(
            TransactionCreateRequest(
              categoryId: _selectedCategory!.id,
              amount: amount,
              operationDate: _date,
              description: _descriptionCtrl.text.trim().isEmpty
                  ? null
                  : _descriptionCtrl.text.trim(),
            ),
          );

      ref.invalidate(transactionsProvider);
      ref.invalidate(dashboardSummaryProvider);
      if (mounted) context.pop();
    } on DioException catch (e) {
      final apiErr = e.error;
      final msg = apiErr is ApiException
          ? apiErr.message
          : 'Не удалось сохранить';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Новая транзакция')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<CategoryType>(
                  segments: const [
                    ButtonSegment(
                      value: CategoryType.expense,
                      label: Text('Расход'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: CategoryType.income,
                      label: Text('Доход'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) {
                    setState(() {
                      _type = s.first;
                      _selectedCategory = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                categoriesAsync.when(
                  data: (list) {
                    if (!_categoryPreselected &&
                        widget.initialCategoryId != null) {
                      final initial = list.firstWhere(
                        (c) => c.id == widget.initialCategoryId,
                        orElse: () => list.first,
                      );
                      _categoryPreselected = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        setState(() {
                          _selectedCategory = initial;
                          _type = initial.type == CategoryType.income
                              ? CategoryType.income
                              : CategoryType.expense;
                        });
                      });
                    }
                    final filtered =
                        list.where((c) => c.type == _type).toList();
                    if (_selectedCategory != null &&
                        !filtered.contains(_selectedCategory)) {
                      _selectedCategory = null;
                    }
                    return DropdownButtonFormField<Category>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Категория',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: filtered
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                      validator: (v) =>
                          v == null ? 'Выберите категорию' : null,
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Ошибка загрузки категорий: $e'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Сумма',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Введите сумму';
                    final parsed = double.tryParse(v.replaceAll(',', '.'));
                    if (parsed == null) return 'Неверный формат';
                    if (parsed <= 0) return 'Должно быть больше 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Дата операции'),
                  subtitle: Text(DateFormat('d MMMM yyyy', 'ru').format(_date)),
                  trailing: TextButton(
                    onPressed: _pickDate,
                    child: const Text('Изменить'),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Описание (необязательно)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Сохранить'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
