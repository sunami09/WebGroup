import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data'; // For displaying images as bytes
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'add_transaction.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class ReceiptScannerPage extends StatefulWidget {
  const ReceiptScannerPage({Key? key}) : super(key: key);

  @override
  _ReceiptScannerPageState createState() => _ReceiptScannerPageState();
}

class _ReceiptScannerPageState extends State<ReceiptScannerPage> {
  Uint8List? _selectedImageBytes; // For Web, store image bytes
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _transactions = []; // To store parsed transactions
  bool _isProcessing = false;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      // Read the image as bytes
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _transactions = []; // Reset transactions
      });
      await _processImage(pickedFile.path); // Process the selected image
    }
  }

  Future<void> _processImage(String imagePath) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      String extractedText;

      if (kIsWeb) {
        // Use cloud-based OCR for web
        if (_selectedImageBytes == null) {
          throw Exception('No image selected.');
        }
        extractedText = await _performCloudOcr(_selectedImageBytes!);
      } else {
        // Use FlutterTesseractOcr for mobile platforms
        extractedText = await FlutterTesseractOcr.extractText(
          imagePath,
          language: 'eng',
        );
      }

      print('Extracted Text: $extractedText');

      if (extractedText.isEmpty) {
        throw Exception('OCR failed to extract text or returned empty string.');
      }

      // Send the extracted text to GPT for classification
      final List<Map<String, dynamic>> transactions =
          await _parseTransactionsWithGPT(extractedText);

      setState(() {
        _transactions = transactions;
      });
    } catch (e, stackTrace) {
      print('Error in _processImage: $e');
      print('StackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<String> _performCloudOcr(Uint8List imageBytes) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.ocr.space/parse/image'),
    );
    request.fields['apikey'] = dotenv.env['OCR_API_KEY']!;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'image.png',
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      final parsedResults = data['ParsedResults'];
      if (parsedResults != null && parsedResults.isNotEmpty) {
        final extractedText = parsedResults[0]['ParsedText'];
        return extractedText;
      } else {
        throw Exception('No text found in image.');
      }
    } else {
      throw Exception('Failed to perform OCR: ${response.reasonPhrase}');
    }
  }

  Future<List<Map<String, dynamic>>> _parseTransactionsWithGPT(String text) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null) {
      throw Exception('API key is missing. Ensure the .env file is loaded.');
    }

    const endpoint = 'https://api.openai.com/v1/chat/completions';

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-4",
        "messages": [
          {
            "role": "system",
            "content":
                "You are a receipt analyzer. Parse receipts into structured transactions."
          },
          {
            "role": "user",
            "content": """
  Parse the following receipt into a list of transactions with fields: amount, type (income/expense), category, and description.

  Text:
  $text

  Output format:
  [
    {"amount": 25, "type": "expense", "category": "Food", "description": "Dinner"},
    {"amount": 800, "type": "expense", "category": "Rent", "description": "Monthly rent"},
    {"amount": 15, "type": "expense", "category": "Miscellaneous", "description": "Snacks"}
  ]
  """
          }
        ],
        "temperature": 0.2,
      }),
    );

    print('API Response Status Code: ${response.statusCode}');
    final responseBody = utf8.decode(response.bodyBytes);
    print('API Response Body: $responseBody');

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);

      if (data['choices'] == null || data['choices'].isEmpty) {
        throw Exception('No choices found in the response.');
      }

      final messageContent = data['choices'][0]['message']['content'];

      if (messageContent == null) {
        throw Exception('No message content found in the response.');
      }

      // Attempt to parse the content as JSON
      try {
        return List<Map<String, dynamic>>.from(jsonDecode(messageContent));
      } catch (e) {
        // Handle non-JSON responses gracefully
        print('Non-JSON Response: $messageContent');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $messageContent')),
        );
        throw Exception(
            'The GPT response is not in the expected JSON format. Content: $messageContent');
      }
    } else {
      throw Exception(
          'OpenAI API request failed: ${response.statusCode} ${response.reasonPhrase} ${response.body}');
    }
  }


  Future<void> _navigateToAddTransactionPage(
      Map<String, dynamic> transaction, int index) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(
          prefilledData: transaction,
          onTransactionAdded: () {
            setState(() {
              _transactions.removeAt(index); // Remove the transaction from the list
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Scanner'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _selectedImageBytes != null
                ? Image.memory(
                    _selectedImageBytes!,
                    height: 300,
                    width: 300,
                    fit: BoxFit.cover,
                  )
                : const Text(
                    'No image selected',
                    style: TextStyle(fontSize: 18),
                  ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Select from Gallery'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 20),
            if (_isProcessing)
              const CircularProgressIndicator()
            else if (_transactions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _transactions[index];
                    return ListTile(
                      title: Text(
                          "${transaction['category']} - \$${transaction['amount']}"),
                      subtitle: Text(
                          "${transaction['description']} (${transaction['type']})"),
                      trailing: SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () =>
                              _navigateToAddTransactionPage(transaction, index),
                          child: const Text('Add'),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
