import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/contract/contract.dart';
import '../../../domain/entities/contract/contract_type.dart';
import '../../../domain/entities/contract/metadata/contract_metadata.dart';
import '../../../domain/usecases/monthly_execution_engine.dart';
import '../../bloc/add_contract/add_contract_barrel.dart';
import '../../theme/calm_theme.dart';
import '../../widgets/calm_components.dart';

class AddContractScreen extends StatefulWidget {
  const AddContractScreen({super.key, this.contract});

  final Contract? contract;

  @override
  State<AddContractScreen> createState() => _AddContractScreenState();
}

class _AddContractScreenState extends State<AddContractScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  ContractType _selectedType = ContractType.fixed;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isLiability = true;
  bool _showOnDashboard = false;

  // Metadata specific fields
  final _lenderController = TextEditingController();
  final _tenureController = TextEditingController();
  final _principalController = TextEditingController();

  final _amountFocus = FocusNode();
  final _principalFocus = FocusNode();
  final _tenureFocus = FocusNode();

  final bool _isAutoCalculating = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    if (widget.contract != null) {
      final c = widget.contract!;
      _nameController.text = c.name;
      _amountController.text = c.monthlyAmount.toString();
      _selectedType = c.type;
      _startDate = c.startDate;
      _endDate = c.endDate;
      _showOnDashboard = c.showOnDashboard;

      if (c.type == ContractType.reducing &&
          c.metadata is ReducingContractMetadata) {
        final meta = c.metadata as ReducingContractMetadata;
        _principalController.text = meta.principalAmount.toString();
        _tenureController.text = meta.tenureMonths.toString();
        _lenderController.text = meta.lenderName ?? '';
      }

      if (c.type == ContractType.fixed && c.metadata is FixedContractMetadata) {
        final meta = c.metadata as FixedContractMetadata;
        _isLiability = meta.isLiability;
      }
    }

    _amountController.addListener(_onFieldChanged);
    _principalController.addListener(_onFieldChanged);
    _tenureController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onFieldChanged);
    _principalController.removeListener(_onFieldChanged);
    _tenureController.removeListener(_onFieldChanged);
    _amountFocus.dispose();
    _principalFocus.dispose();
    _tenureFocus.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (_selectedType != ContractType.reducing || _isAutoCalculating) return;

    final principal = double.tryParse(_principalController.text) ?? 0;
    final emi = double.tryParse(_amountController.text) ?? 0;
    final tenure = int.tryParse(_tenureController.text) ?? 0;

    if (principal <= 0) return;

    setState(() => _validationError = null);

    // Secondary Validation: Is Tenure sufficient for Principal?
    // Even at 0% interest, EMI * Tenure must be >= Principal
    if (emi > 0 && tenure > 0) {
      if (emi * tenure < principal) {
        setState(() {
          final minMonths = (principal / emi).ceil();
          _validationError =
              'Tenure of $tenure ${tenure == 1 ? 'month' : 'months'} is too short. '
              'At ₹${emi.toInt()} per month, it will take at least $minMonths months to pay off ₹${principal.toInt()}.';
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CalmTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: CalmTheme.textPrimary),
        title: Text(
          widget.contract != null ? 'Edit Contract' : 'New Contract',
          style: CalmTheme.textTheme.titleLarge,
        ),
      ),
      body: BlocListener<AddContractCubit, AddContractState>(
        listener: (context, state) {
          if (state is AddContractSuccess) {
            final isEdit = widget.contract != null;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEdit
                      ? 'Contract updated successfully'
                      : 'Contract created successfully',
                ),
              ),
            );
            Navigator.of(context).pop();
          } else if (state is AddContractError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Basic Info'),
                _buildTextField(
                  controller: _nameController,
                  label: 'Contract Name',
                  hint: 'e.g. Home Loan, Netflix',
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildTypeSelector(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _amountController,
                  focusNode: _amountFocus,
                  label: _selectedType == ContractType.fixed
                      ? 'Amount'
                      : 'Monthly Amount',
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                  prefixText: '₹ ',
                  validator: (v) => double.tryParse(v ?? '') == null
                      ? 'Invalid amount'
                      : null,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Dates'),
                _buildDatePicker(
                  label: _selectedType == ContractType.fixed
                      ? 'Date'
                      : 'Start Date',
                  value: _startDate,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => _startDate = date);
                  },
                ),
                if (_selectedType == ContractType.growing) ...[
                  const SizedBox(height: 16),
                  _buildDatePicker(
                    label: 'End Date (Optional)',
                    value: _endDate,
                    isOptional: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            _endDate ??
                            _startDate.add(const Duration(days: 365)),
                        firstDate: _startDate,
                        lastDate: DateTime(2100),
                      );
                      if (date != null) setState(() => _endDate = date);
                    },
                    onClear: () => setState(() => _endDate = null),
                  ),
                ],
                const SizedBox(height: 24),
                _buildTypeSpecificFields(),
                const SizedBox(height: 24),
                _buildDashboardToggle(),
                const SizedBox(height: 48),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: CalmTheme.textTheme.labelMedium?.copyWith(
          color: CalmTheme.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    FocusNode? focusNode,
    String? hint,
    TextInputType? keyboardType,
    String? prefixText,
    String? suffixText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CalmTheme.textTheme.bodySmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          style: CalmTheme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            suffixText: suffixText,
            filled: true,
            fillColor: CalmTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CalmTheme.radiusMd),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contract Type', style: CalmTheme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Row(
          children: ContractType.values.map((type) {
            final isSelected = _selectedType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedType = type;
                  if (_selectedType != ContractType.growing) {
                    _endDate = null;
                  }
                }),
                child: Container(
                  margin: EdgeInsets.only(
                    right: type != ContractType.values.last ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? CalmTheme.primary : CalmTheme.surface,
                    borderRadius: BorderRadius.circular(CalmTheme.radiusMd),
                  ),
                  child: Center(
                    child: Text(
                      type.displayName,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : CalmTheme.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    bool isOptional = false,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CalmTheme.surface,
          borderRadius: BorderRadius.circular(CalmTheme.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: CalmTheme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    value != null
                        ? '${value.day}/${value.month}/${value.year}'
                        : 'Not Set',
                    style: CalmTheme.textTheme.bodyLarge?.copyWith(
                      color: value == null ? CalmTheme.textMuted : null,
                    ),
                  ),
                ],
              ),
            ),
            if (isOptional && value != null)
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onClear,
              )
            else
              Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: CalmTheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificFields() {
    if (_selectedType == ContractType.reducing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Loan Details'),
          _buildTextField(
            controller: _principalController,
            focusNode: _principalFocus,
            label: 'Principal Amount',
            hint: '0.00',
            keyboardType: TextInputType.number,
            prefixText: '₹ ',
            validator: (v) =>
                double.tryParse(v ?? '') == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _tenureController,
            focusNode: _tenureFocus,
            label: 'Tenure (Months)',
            hint: 'e.g. 240',
            keyboardType: TextInputType.number,
            validator: (v) => int.tryParse(v ?? '') == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _lenderController,
            label: 'Lender Name',
            hint: 'e.g. HDFC Bank',
          ),
          const SizedBox(height: 12),
          Text(
            'Interest rate will be calculated automatically based on Principal, Monthly Amount, and Tenure.',
            style: CalmTheme.textTheme.bodySmall?.copyWith(
              color: CalmTheme.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (_validationError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(CalmTheme.radiusMd),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _validationError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    if (_selectedType == ContractType.fixed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Financial Nature'),
          Text(
            'Is this an Asset or a Liability?',
            style: CalmTheme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isLiability = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isLiability
                          ? CalmTheme.primary
                          : CalmTheme.surface,
                      borderRadius: BorderRadius.circular(CalmTheme.radiusMd),
                    ),
                    child: Center(
                      child: Text(
                        'Asset',
                        style: TextStyle(
                          color: !_isLiability
                              ? Colors.white
                              : CalmTheme.textSecondary,
                          fontWeight: !_isLiability
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isLiability = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isLiability
                          ? CalmTheme.primary
                          : CalmTheme.surface,
                      borderRadius: BorderRadius.circular(CalmTheme.radiusMd),
                    ),
                    child: Center(
                      child: Text(
                        'Liability',
                        style: TextStyle(
                          color: _isLiability
                              ? Colors.white
                              : CalmTheme.textSecondary,
                          fontWeight: _isLiability
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isLiability
                ? 'Example: Subscriptions, Insurance, Rent, or Money you owe.'
                : 'Example: Fixed Deposits, Recurring Deposits, or Money owed to you.',
            style: CalmTheme.textTheme.bodySmall?.copyWith(
              color: CalmTheme.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<AddContractCubit, AddContractState>(
      builder: (context, state) {
        final isLoading = state is AddContractSubmitting;
        final hasError = _validationError != null;
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (isLoading || hasError) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasError ? CalmTheme.divider : CalmTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CalmTheme.radiusLg),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.contract != null
                        ? 'Update Contract'
                        : 'Create Contract',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardToggle() {
    return CalmCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: CalmTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.dashboard_outlined, color: CalmTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Show on Dashboard',
                  style: CalmTheme.textTheme.titleMedium,
                ),
                Text(
                  'Pin this contract for quick access',
                  style: CalmTheme.textTheme.bodySmall?.copyWith(
                    color: CalmTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _showOnDashboard,
            onChanged: (v) => setState(() => _showOnDashboard = v),
            activeThumbColor: CalmTheme.primary,
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_validationError != null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.parse(_amountController.text);

    ContractMetadata metadata;
    if (_selectedType == ContractType.reducing) {
      final principal = double.tryParse(_principalController.text) ?? 0;
      final tenure = int.tryParse(_tenureController.text) ?? 0;

      // Calculate interest rate automatically
      const engine = MonthlyExecutionEngine();
      final interestRate = engine.calculateAnnualInterestRate(
        principal: principal,
        emi: amount,
        tenureMonths: tenure,
      );

      metadata = ReducingContractMetadata(
        principalAmount: principal,
        interestRatePercent: interestRate,
        tenureMonths: tenure,
        remainingBalance: principal,
        emiAmount: amount,
        lenderName: _lenderController.text,
      );
    } else if (_selectedType == ContractType.growing) {
      metadata = GrowingContractMetadata(currentValue: 0, totalInvested: 0);
    } else {
      metadata = FixedContractMetadata(
        billingCycle: BillingCycle.monthly,
        isLiability: _isLiability,
      );
    }

    if (widget.contract != null) {
      context.read<AddContractCubit>().updateContract(
        originalContract: widget.contract!,
        name: _nameController.text,
        type: _selectedType,
        monthlyAmount: amount,
        startDate: _startDate,
        endDate: _endDate,
        showOnDashboard: _showOnDashboard,
        metadata: metadata,
      );
    } else {
      context.read<AddContractCubit>().submitContract(
        name: _nameController.text,
        type: _selectedType,
        monthlyAmount: amount,
        startDate: _startDate,
        endDate: _endDate,
        showOnDashboard: _showOnDashboard,
        metadata: metadata,
      );
    }
  }
}
