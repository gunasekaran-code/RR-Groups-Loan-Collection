import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../theme/glass_toast.dart';
import '../../models/agent_collection.dart';
import '../../services/agent_collection_api_service.dart';

// Gold accent used for the primary "Collect" action — matches the
// screenshot's button color. Not currently exposed on AppColors, so it's
// defined locally; move it into AppColors if you want it reused elsewhere.
const Color _kGold = Color(0xFFA9791F);
const Color _kGoldTint = Color(0xFFFBF3E1);

class AgentCollectionScreen extends StatefulWidget {
  const AgentCollectionScreen({super.key});

  @override
  State<AgentCollectionScreen> createState() => _AgentCollectionScreenState();
}

class _AgentCollectionScreenState extends State<AgentCollectionScreen> {
  bool _isLoading = true;
  String? _loadError;
  List<AgentCollectionItem> _items = [];

  int _collectedToday = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final items = await AgentCollectionApiService.fetchAssignedCollections();

      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
      ToastService.show(
        title: 'Failed to load collections',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  int get _customerCount =>
      _items.map((e) => e.customerId ?? e.customerName).toSet().length;

  void _openVisit(AgentCollectionItem item) {
    // Wired to your existing Route Map screen. Adjust the route name if
    // yours differs.
    Navigator.of(context).pushNamed(
      AppRoutes.routeMap,
      arguments: {'customerId': item.customerId, 'loanId': item.loanId},
    );
  }

  void _showCollectSheet(AgentCollectionItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _CollectPaymentSheet(
        item: item,
        onSubmit: (amount, method, date, notes) =>
            _collectPayment(item, amount, method, date, notes),
      ),
    );
  }

  Future<void> _collectPayment(AgentCollectionItem item, double amount,
      String method, DateTime date, String? notes) async {
    try {
      await AgentCollectionApiService.collectPayment(
  item: item,
  amount: amount,
  paymentMethod: method,
  collectionDate: date,
  notes: notes,
);
      if (!mounted) return;
      final now = DateTime.now();
      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      setState(() {
        if (isToday) _collectedToday++;
      });
      ToastService.show(
        title: 'Collection recorded',
        message: item.customerName,
        type: ToastType.success,
      );
      await _load();
    } catch (e) {
      ToastService.show(
        title: 'Failed to record collection',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  void _showProofSheet(AgentCollectionItem item) {
    // TODO: wire to a real "proof of visit / document" upload endpoint once
    // one exists on the backend. For now this just captures a file name
    // locally, matching the upload-box UX from the Collect Payment sheet.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _ProofUploadSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppShell(
      currentRoute: AppRoutes.collections,
      title: 'Collections',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Failed to load collections',
                          style: TextStyle(color: scheme.error)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(_loadError!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 80),
                            const Center(
                              child: Text(
                                'No collections assigned',
                                style: TextStyle(color: AppColors.kTextMuted),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _items.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) return _buildHeader();
                            final item = _items[index - 1];
                            return _CollectionCard(
                              item: item,
                              onCollect: () => _showCollectSheet(item),
                              onVisit: () => _openVisit(item),
                              onProof: () => _showProofSheet(item),
                            );
                          },
                        ),
                ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Collections',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.kTextDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_customerCount customers assigned • $_collectedToday collected today',
            style: const TextStyle(fontSize: 13, color: AppColors.kTextMuted),
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final AgentCollectionItem item;
  final VoidCallback onCollect;
  final VoidCallback onVisit;
  final VoidCallback onProof;

  const _CollectionCard({
    required this.item,
    required this.onCollect,
    required this.onVisit,
    required this.onProof,
  });

  Color get _statusColor {
    switch (item.status) {
      case AgentCollectionStatus.overdue:
        return AppColors.kDanger;
      case AgentCollectionStatus.dueToday:
        return AppColors.kWarning;
      case AgentCollectionStatus.paid:
        return AppColors.kSuccess;
      case AgentCollectionStatus.pending:
        return AppColors.kSuccess;
    }
  }

  Color get _statusBg {
    switch (item.status) {
      case AgentCollectionStatus.overdue:
        return const Color(0xFFFDEBEC);
      case AgentCollectionStatus.dueToday:
        return const Color(0xFFFFF3DC);
      case AgentCollectionStatus.paid:
      case AgentCollectionStatus.pending:
        return const Color(0xFFE7F7EE);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _kGoldTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_alt_outlined, color: _kGold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.customerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.kTextDark)),
                    const SizedBox(height: 2),
                    Text(item.loanNumber,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.kTextMuted)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoBox(label: 'Due Amount', value: item.formattedDueAmount),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoBox(label: 'Due Date', value: item.formattedDueDate),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 16, color: AppColors.kTextMuted),
              const SizedBox(width: 6),
              Text(
                item.contactPhone?.isNotEmpty == true
                    ? item.contactPhone!
                    : 'Contact on file',
                style: const TextStyle(fontSize: 13, color: AppColors.kTextMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onCollect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.currency_rupee, size: 16),
                  label: const Text('Collect'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onVisit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.kTextDark,
                    side: const BorderSide(color: AppColors.kBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.location_on_outlined, size: 16),
                  label: const Text('Visit'),
                ),
              ),
              const SizedBox(width: 8),
              // Expanded(
              //   child: OutlinedButton.icon(
              //     onPressed: onProof,
              //     style: OutlinedButton.styleFrom(
              //       foregroundColor: AppColors.kTextDark,
              //       side: const BorderSide(color: AppColors.kBorder),
              //       padding: const EdgeInsets.symmetric(vertical: 12),
              //       shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(10)),
              //     ),
              //     icon: const Icon(Icons.upload_outlined, size: 16),
              //     label: const Text('Proof'),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.kBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kTextDark)),
        ],
      ),
    );
  }
}

// ==========================================
// COLLECT PAYMENT SHEET (matches the provided screenshot)
// ==========================================
class _CollectPaymentSheet extends StatefulWidget {
  final AgentCollectionItem item;
  final void Function(double amount, String method, DateTime date, String? notes)
      onSubmit;

  const _CollectPaymentSheet({required this.item, required this.onSubmit});

  @override
  State<_CollectPaymentSheet> createState() => _CollectPaymentSheetState();
}
class _CollectPaymentSheetState extends State<_CollectPaymentSheet> {
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
  
  // Replaced String with File for real picking
  File? _screenshotFile;
  File? _signatureFile;
  final ImagePicker _picker = ImagePicker();
  
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.item.dueAmount.round().toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      (double.tryParse(_amountController.text.trim()) ?? 0) > 0 && !_submitting;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _collectionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _collectionDate = picked);
  }

  // Updated _pickFile method
  Future<void> _pickFile({required bool isSignature}) async {
    final source = await _showSourcePicker();
    if (source == null) return;

    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 80, // compress a bit before upload
      maxWidth: 1600,
    );
    if (picked == null) return;

    setState(() {
      if (isSignature) {
        _signatureFile = File(picked.path);
      } else {
        _screenshotFile = File(picked.path);
      }
    });
  }

  // Added Bottom Sheet for Camera vs Gallery
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
                // Ensure you have an appropriate color or use Colors.grey
                color: AppColors.kTextMuted.withOpacity(0.3), 
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.kTextDark),
              title: const Text('Take Photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.kTextDark),
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
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    setState(() => _submitting = true);
    widget.onSubmit(
      amount,
      _methodApiValue[_paymentMethod] ?? 'cash',
      _collectionDate,
      _notesController.text,
      // Note: You will eventually pass your files/URLs here too when wiring up the API!
    );
    if (mounted) Navigator.of(context).pop();
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-${d.year}';
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
                    color: const Color(0xFFFFF9E6), // using hex for _kGoldTint
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Customer',
                              style: TextStyle(fontSize: 12, color: Color(0xFFD4AF37))),
                          Text(widget.item.customerName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.kTextDark)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Loan',
                              style: TextStyle(fontSize: 12, color: Color(0xFFD4AF37))),
                          Text(widget.item.loanNumber,
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
                
                // Updated Upload Boxes
                Row(
                  children: [
                    Expanded(
                      child: _UploadBox(
                        icon: Icons.camera_alt_outlined,
                        label: 'Payment Screenshot',
                        file: _screenshotFile,
                        onTap: () => _pickFile(isSignature: false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _UploadBox(
                        icon: Icons.edit_outlined,
                        label: 'Customer Signature',
                        file: _signatureFile,
                        accent: true,
                        onTap: () => _pickFile(isSignature: true),
                      ),
                    ),
                  ],
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

// ==========================================
// PROOF UPLOAD SHEET
// ==========================================
class _ProofUploadSheet extends StatefulWidget {
  final AgentCollectionItem item;
  const _ProofUploadSheet({required this.item});

  @override
  State<_ProofUploadSheet> createState() => _ProofUploadSheetState();
}

class _ProofUploadSheetState extends State<_ProofUploadSheet> {
  File? _file;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFile() async {
    final source = await _showSourcePicker();
    if (source == null) return;

    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 80, 
      maxWidth: 1600,
    );
    if (picked == null) return;

    setState(() {
      _file = File(picked.path);
    });
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
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.kTextDark),
              title: const Text('Take Photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.kTextDark),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Upload Proof — ${widget.item.customerName}',
                  style: const TextStyle(
                      fontSize: 18,
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
          _UploadBox(
            icon: Icons.upload_file_outlined,
            label: 'Visit / collection proof',
            file: _file,
            onTap: _pickFile,
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
                child: ElevatedButton(
                  onPressed: _file == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          // TODO: Upload logic goes here
                        },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// UPDATED UPLOAD BOX (Supports Image Previews)
// ==========================================
class _UploadBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final File? file;
  final VoidCallback onTap;
  final bool accent;

  const _UploadBox({
    required this.icon,
    required this.label,
    required this.file,
    required this.onTap,
    this.accent = false,
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
          color: hasFile
              ? (accent ? const Color(0xFFF0FDF4) : const Color(0xFFF0F5FF))
              : AppColors.kBackground,
          borderRadius: BorderRadius.circular(10),
          border: hasFile
              ? Border.all(color: accent ? AppColors.kSuccess : AppColors.kInfo)
              : null,
        ),
        child: hasFile
            ? Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(file!, height: 70, width: double.infinity, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap to change',
                    style: TextStyle(
                      fontSize: 11,
                      color: accent ? AppColors.kSuccess : AppColors.kInfo,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Icon(icon, color: AppColors.kTextMuted, size: 22),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
                  ),
                ],
              ),
      ),
    );
  }
}