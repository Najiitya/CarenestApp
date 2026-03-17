import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/app_theme.dart';

enum VerificationState { upload, submitting, pending, rejected }

class CaregiverVerificationPage extends StatefulWidget {
  final int caregiverId;
  final String? applicationStatus;

  const CaregiverVerificationPage({
    super.key,
    required this.caregiverId,
    this.applicationStatus,
  });

  @override
  State<CaregiverVerificationPage> createState() =>
      _CaregiverVerificationPageState();
}

class _CaregiverVerificationPageState
    extends State<CaregiverVerificationPage> {
  final supabase = Supabase.instance.client;
  late VerificationState _currentState;

  PlatformFile? _nicFrontFile;
  PlatformFile? _nicBackFile;
  PlatformFile? _policeReportFile;

  bool _isUploading = false;
  bool _isCheckingStatus = false;
  String? _rejectionReason;

  @override
  void initState() {
    super.initState();
    if (widget.applicationStatus == 'Pending') {
      _currentState = VerificationState.pending;
    } else if (widget.applicationStatus == 'Rejected') {
      _currentState = VerificationState.rejected;
      _loadRejectionReason();
    } else {
      _currentState = VerificationState.upload;
    }
  }

  /// Check if the caregiver has been approved and navigate accordingly
  Future<void> _checkVerificationStatus() async {
    setState(() => _isCheckingStatus = true);

    try {
      // Check caregiver_profiles.verified
      final profile = await supabase
          .from('caregiver_profiles')
          .select('verified')
          .eq('id', widget.caregiverId)
          .maybeSingle();

      if (profile != null && profile['verified'] == true) {
        // Caregiver is now verified — go to dashboard!
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your account has been verified! Welcome!'),
              backgroundColor: AppTheme.primary,
            ),
          );
          Navigator.pushNamedAndRemoveUntil(
              context, '/caregiver_dashboard', (route) => false);
        }
        return;
      }

      // Check application status for rejection
      final app = await supabase
          .from('caregiver_applications')
          .select('status, rejection_reason')
          .eq('caregiver_id', widget.caregiverId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted && app != null) {
        if (app['status'] == 'Approved') {
          // Application approved but profile not yet updated — navigate anyway
          Navigator.pushNamedAndRemoveUntil(
              context, '/caregiver_dashboard', (route) => false);
          return;
        } else if (app['status'] == 'Rejected') {
          setState(() {
            _currentState = VerificationState.rejected;
            _rejectionReason = app['rejection_reason'];
            _isCheckingStatus = false;
          });
          return;
        }
      }

      // Still pending
      if (mounted) {
        setState(() => _isCheckingStatus = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your application is still under review'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking status: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _loadRejectionReason() async {
    try {
      final app = await supabase
          .from('caregiver_applications')
          .select('rejection_reason')
          .eq('caregiver_id', widget.caregiverId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted && app != null) {
        setState(() {
          _rejectionReason = app['rejection_reason'];
        });
      }
    } catch (_) {}
  }

  Future<void> _pickFile(String documentType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;

      // Validate file size (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File must be under 5MB'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        return;
      }

      setState(() {
        switch (documentType) {
          case 'nic_front':
            _nicFrontFile = file;
            break;
          case 'nic_back':
            _nicBackFile = file;
            break;
          case 'police_report':
            _policeReportFile = file;
            break;
        }
      });
    }
  }

  Future<String> _uploadFile(
      PlatformFile file, String docType, int caregiverId) async {
    final fileExt = file.extension ?? 'jpg';
    final filePath =
        'caregiver_$caregiverId/${docType}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    await supabase.storage.from('documents').uploadBinary(
      filePath,
      file.bytes!,
      fileOptions: const FileOptions(upsert: true),
    );

    final publicUrl =
        supabase.storage.from('documents').getPublicUrl(filePath);

    return publicUrl;
  }

  Future<void> _submitDocuments() async {
    if (_nicFrontFile == null ||
        _nicBackFile == null ||
        _policeReportFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload all 3 documents'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _currentState = VerificationState.submitting;
    });

    try {
      final caregiverId = widget.caregiverId;

      // Upload files to Supabase Storage
      final nicFrontUrl =
          await _uploadFile(_nicFrontFile!, 'nic_front', caregiverId);
      final nicBackUrl =
          await _uploadFile(_nicBackFile!, 'nic_back', caregiverId);
      final policeReportUrl =
          await _uploadFile(_policeReportFile!, 'police_report', caregiverId);

      // Get caregiver profile data
      final profile = await supabase
          .from('caregiver_profiles')
          .select('name, email, phone, nic')
          .eq('id', caregiverId)
          .single();

      // Delete any previous rejected application for this caregiver
      await supabase
          .from('caregiver_applications')
          .delete()
          .eq('caregiver_id', caregiverId);

      // Insert new application
      await supabase.from('caregiver_applications').insert({
        'caregiver_id': caregiverId,
        'name': profile['name'],
        'email': profile['email'],
        'phone': profile['phone'],
        'nic': profile['nic'],
        'submitted_date': DateTime.now().toIso8601String().split('T')[0],
        'status': 'Pending',
        'doc_nic_front': nicFrontUrl,
        'doc_nic_back': nicBackUrl,
        'doc_certificate': policeReportUrl,
      });

      // Also insert into caregiver_documents
      await supabase.from('caregiver_documents').insert([
        {
          'caregiver_id': caregiverId,
          'type': 'nic_front',
          'document_url': nicFrontUrl
        },
        {
          'caregiver_id': caregiverId,
          'type': 'nic_back',
          'document_url': nicBackUrl
        },
        {
          'caregiver_id': caregiverId,
          'type': 'police_report',
          'document_url': policeReportUrl
        },
      ]);

      if (mounted) {
        setState(() {
          _currentState = VerificationState.pending;
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentState = VerificationState.upload;
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Verification',
          style: AppTheme.headingMedium.copyWith(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentState) {
      case VerificationState.upload:
        return _buildUploadState();
      case VerificationState.submitting:
        return _buildSubmittingState();
      case VerificationState.pending:
        return _buildPendingState();
      case VerificationState.rejected:
        return _buildRejectedState();
    }
  }

  // ─── UPLOAD STATE ────────────────────────────

  Widget _buildUploadState() {
    final allSelected = _nicFrontFile != null &&
        _nicBackFile != null &&
        _policeReportFile != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.softGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Verify Your Identity',
                    style: AppTheme.headingLarge
                        .copyWith(fontSize: 22)),
                const SizedBox(height: 8),
                Text(
                  'Please upload the following documents to get verified and start accepting care requests.',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyText,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Document upload cards
          _buildDocumentCard(
            icon: Icons.credit_card,
            title: 'NIC Front',
            description: 'Front side of your National Identity Card',
            file: _nicFrontFile,
            onPick: () => _pickFile('nic_front'),
            onRemove: () => setState(() => _nicFrontFile = null),
          ),
          const SizedBox(height: 12),

          _buildDocumentCard(
            icon: Icons.credit_card,
            title: 'NIC Back',
            description: 'Back side of your National Identity Card',
            file: _nicBackFile,
            onPick: () => _pickFile('nic_back'),
            onRemove: () => setState(() => _nicBackFile = null),
          ),
          const SizedBox(height: 12),

          _buildDocumentCard(
            icon: Icons.description,
            title: 'Police Report',
            description: 'Recent police clearance certificate',
            file: _policeReportFile,
            onPick: () => _pickFile('police_report'),
            onRemove: () => setState(() => _policeReportFile = null),
          ),

          const SizedBox(height: 8),
          Text(
            'Accepted formats: JPG, PNG, PDF (max 5MB each)',
            style: AppTheme.bodyText.copyWith(fontSize: 12),
          ),

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: allSelected ? _submitDocuments : null,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Submit for Verification'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    allSelected ? AppTheme.primary : Colors.grey[300],
                foregroundColor:
                    allSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Logout
          TextButton.icon(
            onPressed: _handleLogout,
            icon: Icon(Icons.logout, color: AppTheme.textGrey, size: 18),
            label: Text('Logout',
                style: AppTheme.bodyText.copyWith(fontSize: 13)),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required IconData icon,
    required String title,
    required String description,
    required PlatformFile? file,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final bool hasFile = file != null;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasFile ? AppTheme.primary : Colors.grey.shade200,
          width: hasFile ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasFile ? AppTheme.softGreen : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                hasFile ? Icons.check_circle : icon,
                color: hasFile ? AppTheme.primary : AppTheme.textGrey,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTheme.headingMedium.copyWith(fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    hasFile ? file.name : description,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 12,
                      color:
                          hasFile ? AppTheme.primary : AppTheme.textGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Action button
            if (hasFile)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, color: AppTheme.error, size: 20),
              )
            else
              OutlinedButton(
                onPressed: onPick,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Upload', style: TextStyle(fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }

  // ─── SUBMITTING STATE ────────────────────────

  Widget _buildSubmittingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          const SizedBox(height: 24),
          Text('Uploading documents...', style: AppTheme.headingMedium),
          const SizedBox(height: 8),
          Text('Please wait while we upload your files.',
              style: AppTheme.bodyText),
        ],
      ),
    );
  }

  // ─── PENDING STATE ───────────────────────────

  Widget _buildPendingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Hourglass icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppTheme.softGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: AppTheme.primary,
              size: 60,
            ),
          ),

          const SizedBox(height: 28),

          Text('Verification Pending',
              style: AppTheme.headingLarge.copyWith(fontSize: 24)),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Your documents have been submitted and are under review. You will be notified once your verification is complete.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyText.copyWith(height: 1.6),
            ),
          ),

          const SizedBox(height: 32),

          // Progress timeline card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildTimelineStep(
                  icon: Icons.check_circle,
                  color: AppTheme.primary,
                  title: 'Documents Submitted',
                  subtitle: 'Your documents have been received',
                  isCompleted: true,
                ),
                _buildTimelineConnector(isActive: true),
                _buildTimelineStep(
                  icon: Icons.pending,
                  color: Colors.orange,
                  title: 'Under Review',
                  subtitle: 'Admin is reviewing your documents',
                  isCompleted: false,
                  isActive: true,
                ),
                _buildTimelineConnector(isActive: false),
                _buildTimelineStep(
                  icon: Icons.verified,
                  color: Colors.grey.shade400,
                  title: 'Verification Complete',
                  subtitle: 'You can start accepting requests',
                  isCompleted: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Check Status button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isCheckingStatus ? null : _checkVerificationStatus,
              icon: _isCheckingStatus
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh),
              label: Text(
                  _isCheckingStatus ? 'Checking...' : 'Check Verification Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: AppTheme.error),
              label: const Text('Logout',
                  style: TextStyle(color: AppTheme.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isActive = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.headingMedium.copyWith(
                  fontSize: 14,
                  color: isCompleted || isActive
                      ? AppTheme.textDark
                      : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 12,
                  color: isCompleted || isActive
                      ? AppTheme.textGrey
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector({required bool isActive}) {
    return Container(
      margin: const EdgeInsets.only(left: 13),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        width: 2,
        height: 28,
        color: isActive ? AppTheme.primary : Colors.grey.shade300,
      ),
    );
  }

  // ─── REJECTED STATE ──────────────────────────

  Widget _buildRejectedState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Error icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.error.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cancel_outlined,
              color: AppTheme.error,
              size: 60,
            ),
          ),

          const SizedBox(height: 28),

          Text('Application Rejected',
              style: AppTheme.headingLarge.copyWith(
                  fontSize: 24, color: AppTheme.error)),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Unfortunately, your verification application was not approved. Please review the reason below and resubmit.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyText.copyWith(height: 1.6),
            ),
          ),

          const SizedBox(height: 24),

          // Rejection reason card
          if (_rejectionReason != null && _rejectionReason!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: AppTheme.error, width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reason for Rejection',
                      style: AppTheme.headingMedium.copyWith(
                          fontSize: 14, color: AppTheme.error)),
                  const SizedBox(height: 8),
                  Text(_rejectionReason!, style: AppTheme.bodyText),
                ],
              ),
            ),

          const SizedBox(height: 32),

          // Resubmit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _nicFrontFile = null;
                  _nicBackFile = null;
                  _policeReportFile = null;
                  _currentState = VerificationState.upload;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Resubmit Documents'),
            ),
          ),

          const SizedBox(height: 16),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: AppTheme.error),
              label: const Text('Logout',
                  style: TextStyle(color: AppTheme.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
