import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../models/agent_collection.dart';

const Color kCollectGold = Color(0xFFA9791F);

/// Bottom sheet used to record a collection.
///
/// [subtitleLabel]/[subtitleValue] describe what's being collected — a
/// single loan number, or "3 loans" when collecting a lump sum against a
/// whole customer group. [prefillAmount] is filled into the amount field
/// but stays fully editable.
class CollectPaymentSheet extends StatefulWidget {
  final String customerName;
  final String subtitleLabel;
  final String subtitleValue;
  final double prefillAmount;
  final double? installmentAmount;
  final double? dueAmount;
  final double? penaltyAmount;
  final double? outstandingBalance;
  final int? dueCount;
  final void Function(
    double amount,
    String method,
    DateTime date,
    String? notes,
  ) onSubmit;

  const CollectPaymentSheet({
    super.key,
    required this.customerName,
    required this.subtitleLabel,
    required this.subtitleValue,
    required this.prefillAmount,
    this.installmentAmount,
    this.dueAmount,
    this.penaltyAmount,
    this.outstandingBalance,
    this.dueCount,
    required this.onSubmit,
  });

  @override
  State<CollectPaymentSheet> createState() => _CollectPaymentSheetState();
}

class _CollectPaymentSheetState extends State<CollectPaymentSheet> {
  static const List<String> _paymentMethods = [
    'Cash',
    'UPI',
    'Bank Transfer',
    'Cheque',
    'Card',
  ];
  static const Map<String, String> _methodApiValue = {
    'Cash': 'cash',
    'UPI': 'upi',
    'Bank Transfer': 'bank',
    'Cheque': 'cheque',
    'Card': 'card',
  };

  late final TextEditingController _amountController;
  final TextEditingController _notesController = TextEditingController();
  String _paymentMethod = 'Cash';
  DateTime _collectionDate = DateTime.now();

  File? _screenshotFile;
  final ImagePicker _picker = ImagePicker();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.prefillAmount.round().toString(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

    double get _emi =>
      widget.installmentAmount != null && widget.installmentAmount! > 0
        ? widget.installmentAmount!
        : (widget.dueAmount ?? widget.prefillAmount);
    double get _due => widget.dueAmount ?? widget.prefillAmount;
    double get _penalty => widget.penaltyAmount ?? 0;
    double get _fullBalance =>
      widget.outstandingBalance ?? (_due + _penalty);

  bool get _canSave => _amount > 0 && !_submitting;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _collectionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _collectionDate = picked);
  }

  Future<void> _pickScreenshot() async {
    final source = await _showSourcePicker();
    if (source == null) return;

    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return;

    setState(() => _screenshotFile = File(picked.path));
  }

  Future<ImageSource?> _showSourcePicker() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.kTextMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt_outlined, color: AppColors.kTextDark),
              title: const Text('Take Photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.kTextDark),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_canSave) return;
    setState(() => _submitting = true);
    widget.onSubmit(
      _amount,
      _methodApiValue[_paymentMethod] ?? 'cash',
      _collectionDate,
      _notesController.text,
    );
    if (mounted) Navigator.of(context).pop();
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  void _setAmount(double amount) {
    _amountController.text = amount.round().toString();
    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _amountController.text.length),
    );
    setState(() {});
  }

  Widget _amountAction(String label, double amount, Color color) {
    return ElevatedButton(
      onPressed: () => _setAmount(amount),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: color == const Color(0xFFFFF0C2)
            ? const Color(0xFF8A5A00)
            : Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text('$label (${AgentCollectionItem.formatAmount(amount)})'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardPadding),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        decoration: const BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Collect Payment',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextDark)),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, color: AppColors.kTextMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Customer',
                              style:
                                  TextStyle(fontSize: 12, color: Color(0xFFD4AF37))),
                          Text(widget.customerName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.kTextDark)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(widget.subtitleLabel,
                              style:
                                  const TextStyle(fontSize: 12, color: Color(0xFFD4AF37))),
                          Text(widget.subtitleValue,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.kTextDark)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('AMOUNT RECEIVED *'),
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                prefixText: '₹  ', hintText: '0', isDense: true),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('PAYMENT METHOD'),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _paymentMethod,
                            decoration: const InputDecoration(isDense: true),
                            items: _paymentMethods
                                .map((m) =>
                                    DropdownMenuItem(value: m, child: Text(m)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _paymentMethod = v ?? 'Cash'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _amountAction('⚡ 1 EMI', _emi, const Color(0xFFFFF0C2)),
                    _amountAction(
                      '⚡ Pay Dues${widget.dueCount != null ? ' · ${widget.dueCount} Due' : ''}',
                      _due,
                      const Color(0xFFC8103D),
                    ),
                    _amountAction(
                      '⚡ Due + Penalty', _due + _penalty,
                      const Color(0xFFFFE1E7),
                    ),
                    _amountAction(
                      '⚡ Full Balance', _fullBalance,
                      const Color(0xFFC9F5DF),
                    ),
                  ],
                ),
                if (_penalty > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6),
                      border: Border.all(color: const Color(0xFFFFD45C)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '⚠ Penalty: ${AgentCollectionItem.formatAmount(_penalty)}\n'
                      'Overdue due: ${AgentCollectionItem.formatAmount(_due)} · '
                      'Total due: ${AgentCollectionItem.formatAmount(_due + _penalty)}',
                      style: const TextStyle(color: Color(0xFF7A4311)),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _label('COLLECTION DATE'),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(isDense: true),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDate(_collectionDate)),
                        const Icon(Icons.calendar_today_outlined, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _label('NOTES'),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      hintText: 'Optional notes about this collection...',
                      isDense: true),
                ),
                const SizedBox(height: 16),
                _label('PAYMENT SCREENSHOT (OPTIONAL)'),
                _UploadBox(
                  icon: Icons.camera_alt_outlined,
                  label: 'Payment Screenshot',
                  file: _screenshotFile,
                  onTap: _pickScreenshot,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kSuccess,
                        ),
                        onPressed: _canSave ? _submit : null,
                        icon: const Icon(Icons.print_outlined, size: 18),
                        label: Text(_submitting ? 'Saving...' : 'Generate Receipt'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextMuted)),
      );
}

class _UploadBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final File? file;
  final VoidCallback onTap;

  const _UploadBox({
    required this.icon,
    required this.label,
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: hasFile ? const Color(0xFFF0F5FF) : AppColors.kBackground,
          borderRadius: BorderRadius.circular(10),
          border: hasFile ? Border.all(color: AppColors.kInfo) : null,
        ),
        child: hasFile
            ? Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(file!,
                        height: 70, width: double.infinity, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap to change',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.kInfo,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppColors.kTextMuted, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
                  ),
                ],
              ),
      ),
    );
  }
}