import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/app_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/firebase_service.dart';
import 'package:mantri_app/generated/app_localizations.dart';

class SendMessageScreen extends ConsumerStatefulWidget {
  const SendMessageScreen({super.key});

  @override
  ConsumerState<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends ConsumerState<SendMessageScreen> {
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSeniorCitizen = false;
  bool _isSeniorCitizenLocked = false;
  bool _isMediaContact = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-calculate senior citizen status on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(laravelUserProvider);
      if (user?.dob != null && user!.dob!.isNotEmpty) {
        try {
          final dob = DateTime.parse(user.dob!);
          final age = DateTime.now().year - dob.year;
          setState(() {
            _isSeniorCitizen = age >= 60;
            _isSeniorCitizenLocked = true;
          });
        } catch (e) {
          // ignore parsing error
        }
      }
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(laravelUserProvider);
    if (user == null) return;

    if (_subjectController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      AppDialogs.showErrorDialog(context);
      return;
    }

    setState(() => _isLoading = true);

    final msg = CitizenMessage(
      id: '',
      userId: user.uid,
      userName: user.name,
      userEmail: user.email,
      phone: user.phone,
      subject: _subjectController.text.trim(),
      body: _bodyController.text.trim(),
      priority: 'Medium', // calculated automatically on backend
      status: 'Pending',
      isEscalated: false,
      isSeniorCitizen: _isSeniorCitizen,
      isMediaContact: _isMediaContact,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(apiServiceProvider).addMessage(msg);
      if (mounted) {
        await AppDialogs.showSuccessDialog(context, message: AppLocalizations.of(context).messageSentSuccess);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, userMessage: 'Failed to send message:', technicalError: e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFFDB7E20);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).sendMessageToMp),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).messageSubmitDesc,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).subject,
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _bodyController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).messageDetails,
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 6,
            ),
            const SizedBox(height: 16),

            CheckboxListTile(
              title: Text(AppLocalizations.of(context).iAmSeniorCitizen, style: GoogleFonts.poppins(fontSize: 13)),
              subtitle: Text(AppLocalizations.of(context).helpsPrioritize, style: const TextStyle(fontSize: 11)),
              value: _isSeniorCitizen,
              activeColor: themeColor,
              onChanged: _isSeniorCitizenLocked 
                  ? null 
                  : (val) {
                      setState(() => _isSeniorCitizen = val ?? false);
                    },
            ),

            CheckboxListTile(
              title: Text(AppLocalizations.of(context).iAmMediaContact, style: GoogleFonts.poppins(fontSize: 13)),
              value: _isMediaContact,
              activeColor: themeColor,
              onChanged: (val) {
                setState(() => _isMediaContact = val ?? false);
              },
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        AppLocalizations.of(context).sendMessage,
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
