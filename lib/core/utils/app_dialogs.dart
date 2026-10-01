import 'package:flutter/material.dart';

class AppDialogs {
  static bool _isDialogOpen = false;

  /// Private base method to show a customized popup dialog
  static Future<void> _showPopup(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color buttonColor,
  }) async {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    _isDialogOpen = false;
  }

  /// Shows a centered error dialog.
  static Future<void> showErrorDialog(
    BuildContext context, {
    String? userMessage,
    dynamic technicalError,
  }) async {
    // Log the technical error to console
    if (technicalError != null) {
      debugPrint('Technical Error: $technicalError');
    }

    // Clean up the message for the user
    String displayMessage = userMessage ?? 'Something went wrong. Please try again.';
    
    // If no userMessage provided but technicalError is, map common cases or fallback
    if (userMessage == null && technicalError != null) {
      final errorStr = technicalError.toString().toLowerCase();
      if (errorStr.contains('socket') || errorStr.contains('network') || errorStr.contains('timeout')) {
        displayMessage = 'Network error. Please check your connection and try again.';
      } else if (technicalError.toString().startsWith('Exception: ')) {
         displayMessage = technicalError.toString().replaceFirst('Exception: ', '');
      } else {
         displayMessage = 'Something went wrong. Please try again.';
      }
    }

    await _showPopup(
      context,
      title: 'Error',
      message: displayMessage,
      icon: Icons.error_outline,
      iconColor: Colors.redAccent,
      buttonColor: const Color(0xFFDB7E20), // App Saffron Theme
    );
  }

  /// Shows a centered success dialog.
  static Future<void> showSuccessDialog(
    BuildContext context, {
    required String message,
  }) async {
    await _showPopup(
      context,
      title: 'Success',
      message: message,
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
      buttonColor: const Color(0xFFDB7E20),
    );
  }

  /// Shows a centered warning dialog.
  static Future<void> showWarningDialog(
    BuildContext context, {
    required String message,
  }) async {
    await _showPopup(
      context,
      title: 'Warning',
      message: message,
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.orange,
      buttonColor: const Color(0xFFDB7E20),
    );
  }

  /// Shows a centered info dialog.
  static Future<void> showInfoDialog(
    BuildContext context, {
    required String message,
  }) async {
    await _showPopup(
      context,
      title: 'Information',
      message: message,
      icon: Icons.info_outline,
      iconColor: Colors.blueAccent,
      buttonColor: const Color(0xFFDB7E20),
    );
  }

  /// Shows a logout confirmation dialog and returns true if user confirmed.
  static Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
    bool confirmed = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                confirmed = true;
                Navigator.pop(ctx);
              },
              child: const Text('Logout / Yes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    return confirmed;
  }

  /// Shows an exit confirmation dialog and returns true if user confirmed exit.
  static Future<bool> showExitConfirmationDialog(BuildContext context) async {
    bool confirmed = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text('Exit App'),
          content: const Text('Are you sure you want to close the app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB7E20), // Saffron
              ),
              onPressed: () {
                confirmed = true;
                Navigator.pop(ctx);
              },
              child: const Text('Exit / Yes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    return confirmed;
  }
}
