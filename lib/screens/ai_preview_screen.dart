import 'dart:convert';
import 'package:flutter/material.dart';

class AiPreviewScreen extends StatelessWidget {
  final String? title;
  final String? body;
  final String? imageBase64;

  const AiPreviewScreen({Key? key, this.title, this.body, this.imageBase64}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Vista IA', style: TextStyle(color: Colors.black87)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageBase64 != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(base64Decode(imageBase64!), fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
            ],
            if (title != null) ...[
              Text(title!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
            ],
            if (body != null) ...[
              Text(body!, style: const TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 20),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Return values to caller so they can apply to form
                      Navigator.pop(context, {
                        'title': title,
                        'body': body,
                        'image': imageBase64,
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B9FED)),
                    child: const Text('Usar en publicación'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
