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
  final _interestController = TextEditingController();

  final _amountFocus = FocusNode();
  final _principalFocus = FocusNode();
  final _tenureFocus = FocusNode();
  final _interestFocus = FocusNode();

  bool _isAutoCalculating = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onFieldChanged);
    _principalController.addListener(_onFieldChanged);
    _tenureController.addListener(_onFieldChanged);
    _interestController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onFieldChanged);
    _principalController.removeListener(_onFieldChanged);
    _tenureController.removeListener(_onFieldChanged);
    _interestController.removeListener(_onFieldChanged);
    _amountFocus.dispose();
    _principalFocus.dispose();
    _tenureFocus.dispose();
    _interestFocus.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (_selectedType != ContractType.reducing || _isAutoCalculating) return;

    final principal = double.tryParse(_principalController.text) ?? 0;
    final emi = double.tryParse(_amountController.text) ?? 0;
    final interest = double.tryParse(_interestController.text) ?? 0;
    final tenure = int.tryParse(_tenureController.text) ?? 0;

    if (principal <= 0) return;

    setState(() => _validationError = null);
    const engine = MonthlyExecutionEngine();

    // Primary Validation: Is EMI enough to cover interest?
    if (emi > 0 && interest > 0) {
      final monthlyInterest = principal * (interest / 12 / 100);
      if (emi <= monthlyInterest) {
        setState(() {
          _validationError =
              'Monthly amount must be greater than ₹${monthlyInterest.toStringAsFixed(2)} to cover interest.';
          // Clear tenure as it's now invalid (infinite)
          _isAutoCalculating = true;
          _tenureController.clear();
          _isAutoCalculating = false;
        });
        return;
      }
    }

    if (_interestFocus.hasFocus) {
      // Typing Interest: Only auto-calculate Tenure
      if (emi > 0) {
        _calculateAndSetTenure(engine, principal, interest, emi);
      }
    } else if (_tenureFocus.hasFocus) {
      // Typing Tenure: Only auto-calculate Interest
      if (emi > 0) {
        _calculateAndSetInterest(engine, principal, emi, tenure);
      }
    } else if (_amountFocus.hasFocus || _principalFocus.hasFocus) {
      // Typing EMI or Principal: Update Tenure if Interest exists, else update Interest if Tenure exists
      if (interest > 0) {
        _calculateAndSetTenure(engine, principal, interest, emi);
      } else if (tenure > 0) {
        _calculateAndSetInterest(engine, principal, emi, tenure);
      }
    }
  }

  void _calculateAndSetTenure(
    MonthlyExecutionEngine engine,
    double principal,
    double interest,
    double emi,
  ) {
    if (emi <= 0) return;
    final calculated = engine.calculateRemainingTenure(
      balance: principal,
      annualInterestRate: interest,
      emi: emi,
    );
    if (calculated > 0 && calculated < 999) {
      _isAutoCalculating = true;
      _tenureController.text = calculated.toString();
      _isAutoCalculating = false;
    }
  }

  void _calculateAndSetInterest(
    MonthlyExecutionEngine engine,
    double principal,
    double emi,
    int tenure,
  ) {
    if (tenure <= 0 || emi <= 0) return;
    final calculated = engine.calculateAnnualInterestRate(
      principal: principal,
      emi: emi,
      tenureMonths: tenure,
    );
    // Allow 0 or positive
    _isAutoCalculating = true;
    _interestController.text = calculated.toStringAsFixed(2);
    _isAutoCalculating = false;
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
    required DateTime value,
    required VoidCallback onTap,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: CalmTheme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  '${value.day}/${value.month}/${value.year}',
                  style: CalmTheme.textTheme.bodyLarge,
                ),
              ],
            ),
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
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _interestController,
            focusNode: _interestFocus,
            label: 'Interest Rate (Annual %)',
            hint: 'e.g. 8.5',
            keyboardType: TextInputType.number,
            suffixText: '%',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _tenureController,
            focusNode: _tenureFocus,
            label: 'Tenure (Months)',
            hint: 'e.g. 240',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _lenderController,
            label: 'Lender Name',
            hint: 'e.g. HDFC Bank',
          ),
          const SizedBox(height: 12),
          Text(
            'Keep either Tenure or Interest empty to auto-calculate based on Principal and Monthly Amount.',
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
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: CalmTheme.primary,
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
      metadata = ReducingContractMetadata(
        principalAmount: double.tryParse(_principalController.text) ?? 0,
        interestRatePercent: double.tryParse(_interestController.text) ?? 0,
        tenureMonths: int.tryParse(_tenureController.text) ?? 0,
        remainingBalance: double.tryParse(_principalController.text) ?? 0,
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
      metadata: metadata,
    );
  }
}
