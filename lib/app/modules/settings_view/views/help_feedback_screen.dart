import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapstar_app/app/core/utils/helpers.dart';

class HelpFeedbackScreen extends StatelessWidget {
  const HelpFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final messageCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Help and Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tell us your issue or suggestion'),
            const SizedBox(height: 12),
            TextField(
              controller: messageCtrl,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Write your feedback... ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final msg = messageCtrl.text.trim();
                  if (msg.isEmpty) {
                    AppHelpers.showSnackBar(
                      title: 'Feedback',
                      message: 'Please enter your feedback first',
                      isError: true,
                    );
                    return;
                  }

                  AppHelpers.showSnackBar(
                    title: 'Feedback',
                    message: 'Thanks. Your feedback has been recorded.',
                    isError: false,
                  );
                  Get.back();
                },
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
