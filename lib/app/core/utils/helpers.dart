import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../themes/app_colors.dart';

class AppHelpers
{

    static void showSnackBar({
        IconData? icon,
        required String title,
        required String message,
        bool? isError,
        Duration duration = const Duration(seconds: 3),
        String? actionLabel, // optional button label
        VoidCallback? onActionTap // button tap callback
    }) 
    {
        Get.snackbar(
            title,
            message,
            // snackPosition: SnackPosition.BOTTOM,
            backgroundColor: isError == true ? Colors.red.withValues(alpha: 0.25) : isError == false ? Colors.green.withValues(alpha: 0.25) : null,
            icon: Icon(
                isError == true ? Icons.error : isError == false ? Icons.check_circle : icon,
                color: isError == true ? Colors.red : isError == false ? Colors.green : null
            ),
            margin: const EdgeInsets.all(16),
            borderRadius: 8,
            duration: duration,
            dismissDirection: DismissDirection.horizontal,
            mainButton: actionLabel != null && onActionTap != null
                ? TextButton(
                    onPressed: ()
                    {
                        onActionTap();
                        if (Get.isSnackbarOpen) Get.back();
                    },
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary
                    ),
                    child: Text(
                        actionLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold
                        )
                    )
                )
                : null
        );
    }

  /* static void showSnackBar({
    required String title,
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3)
  }) {
    Get.snackbar(
      title,
      message,
      // snackPosition: SnackPosition.BOTTOM,
      // dismissDirection: DismissDirection.horizontal,
      backgroundColor: isError ? Colors.red[200] : Colors.green[200],
      icon: Icon(
        isError ? Icons.error : Icons.check_circle,
        color: isError ? Colors.red : Colors.green,
      ),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: duration,
    );
  }*/

    static void showLoadingDialog({String message = "Loading..."}) 
    {
        Get.dialog(AlertDialog(content: Row(
                    children: [
                        const CircularProgressIndicator(),
                        const SizedBox(width: 16),
                        Text(message)
                    ]
                )),
            barrierDismissible: false
        );
    }

    /// ✅ Currency format helper
    static String formatCurrency(num value, {String symbol = '₹ '})
    {
        final format = NumberFormat.currency(
            locale: 'en_IN', // Indian locale
            symbol: symbol,
            decimalDigits: 0 // without paisa
        );
        return format.format(value);
    }

    static String getErrorGif(String? message) {
      switch (message) {
        case "Connection error":
          return 'assets/icons/no_connection.svg';
        default:
          return 'assets/gifs/something_wrong.gif';
      }
    }


}
