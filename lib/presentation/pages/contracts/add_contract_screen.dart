import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/contract/contract_type.dart';
import '../../../domain/entities/contract/metadata/contract_metadata.dart';
import '../../../domain/usecases/monthly_execution_engine.dart';
import '../../bloc/add_contract/add_contract_barrel.dart';
import '../../theme/calm_theme.dart';

class AddContractScreen extends StatefulWidget {
  const AddContractScreen({super.key});

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

  // Metadata specific fields
  final _lenderController = TextEditingController();
  final _tenureController = TextEditingController();
  final _principalController = TextEditingController();

  final _amountFocus = FocusNode();
  final _principalFocus = FocusNode();
  final _tenureFocus = FocusNode();

  bool _isAutoCalculating = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
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
        title: Text('New Contract', style: CalmTheme.textTheme.titleLarge),
      ),
      body: BlocListener<AddContractCubit, AddContractState>(
        listener: (context, state) {
          if (state is AddContractSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contract created successfully')),
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
                  label: 'Monthly Amount',
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
                  label: 'Start Date',
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
                const SizedBox(height: 16),
                _buildDatePicker(
                  label: 'End Date (Optional)',
                  value: _endDate,
                  isOptional: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate:
                          _endDate ?? _startDate.add(const Duration(days: 365)),
                      firstDate: _startDate,
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => _endDate = date);
                  },
                  onClear: () => setState(() => _endDate = null),
                ),
                const SizedBox(height: 24),
                _buildTypeSpecificFields(),
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
                onTap: () => setState(() => _selectedType = type),
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
                : const Text(
                    'Create Contract',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        );
      },
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
      metadata = const FixedContractMetadata(
        billingCycle: BillingCycle.monthly,
      );
    }

    context.read<AddContractCubit>().submitContract(
      name: _nameController.text,
      type: _selectedType,
      monthlyAmount: amount,
      startDate: _startDate,
      endDate: _endDate,
      metadata: metadata,
    );
  }
}
