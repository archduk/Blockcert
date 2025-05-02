import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'qr_code_scanner.dart';
import 'package:file_picker/file_picker.dart';

// Replace with your actual Starton API key
const String startonApiKey = '';
// Replace with your server's endpoint for recording verification results.
const String recordVerificationUrl = 'http://block_cert/record_verification.php';

Future<Map<String, dynamic>> fetchCertificateFromIPFS(String ipfsHash) async {
  final url = 'https://ipfs.starton.io/ipfs/$ipfsHash';

  final response = await http.get(
    Uri.parse(url),
    headers: {
      'X-API-KEY': startonApiKey,
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return {'success': true, 'data': data};
  } else {
    return {
      'success': false,
      'message':
      'Failed to fetch file from IPFS. Status code: ${response.statusCode}. Response body: ${response.body}',
    };
  }
}

class CertificateAuthenticationScreen extends StatefulWidget {
  final bool isDarkMode;
  const CertificateAuthenticationScreen({super.key, required this.isDarkMode});

  @override
  State<CertificateAuthenticationScreen> createState() =>
      _CertificateAuthenticationScreenState();
}

class _CertificateAuthenticationScreenState
    extends State<CertificateAuthenticationScreen> {
  final TextEditingController certificateIdController = TextEditingController();
  final TextEditingController studentNameController = TextEditingController();
  PlatformFile? uploadedTranscript;
  bool _isLoading = false;
  bool _isVerificationComplete = false;
  bool _verificationSuccess = false;
  String _verificationMessage = '';
  String? _certificateName;
  String? _certificateIssuer;
  String? _certificateId;
  String? _certificateDate;
  String? _certificateProgram;
  // Add a method to send verification data to the server
  Future<void> _recordVerificationResult({
    required bool isSuccess,
    required String certificateId,
    required String type,
    String? studentName,
    String? message,
    Map<String, dynamic>? details,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(recordVerificationUrl),
        body: {
          'is_success': isSuccess.toString(),
          'certificate_id': certificateId,
          'type': type,
          'student_name': studentName,
          'message': message,
          'details': details != null ? jsonEncode(details) : '',
        },
      );

      if (response.statusCode != 200) {
        // Log the error to the console.  Important for debugging.
        print('Failed to record verification result: ${response.body}');
        // Optionally, show a user-facing error message (without halting the program).
        _showResultDialog(
          'Error',
          'Failed to record verification result. Please check the connection.',
        );
      } else {
        final responseData = json.decode(response.body);
        if (responseData['status'] != 'success') {
          print('Failed to record verification result: ${responseData['message']}');
          _showResultDialog(
            'Error',
            'Failed to record verification result: ${responseData['message']}',
          );
        }
      }
    } catch (e) {
      //  Log the error.
      print('Error recording verification result: $e');
      _showResultDialog(
        'Error',
        'Failed to record verification result. An error occurred.',
      );
    }
  }

  ThemeData _buildThemeData() {
    return widget.isDarkMode
        ? ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black87,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.white),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 1.0),
        ),
      ),
    )
        : ThemeData.light().copyWith(
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.black),
        bodyLarge: TextStyle(color: Colors.black),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.black),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 1.0),
        ),
      ),
    );
  }

  Future<void> _verify() async {
    String certId = certificateIdController.text.trim();
    String studentName = studentNameController.text.trim();
    bool isTranscript = uploadedTranscript != null;
    String type = isTranscript ? 'Transcript' : 'Certificate';

    if ((certId.isEmpty && !isTranscript) || (!isTranscript && studentName.isEmpty)) {
      _showResultDialog('Error', 'Please enter all required fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _isVerificationComplete = false;
      _certificateName = null;
      _certificateIssuer = null;
      _certificateId = null;
      _certificateDate = null;
      _certificateProgram = null;
    });

    try {
      Map<String, dynamic>? verificationResult;
      if (isTranscript) {
        bool isSuccess = _verifyTranscriptSignature(uploadedTranscript!);
        verificationResult = _handleVerificationResult(
          isSuccess,
          isSuccess ? 'Transcript verified' : 'Invalid signature',
          uploadedTranscript!.name,
          type,
        );
        await _recordVerificationResult(
          isSuccess: isSuccess,
          certificateId: uploadedTranscript!.name, // Use filename for transcript
          type: type,
          message: isSuccess ? 'Transcript verified' : 'Invalid signature',
        );
      } else {
        if (certId.startsWith('Qm')) {
          final ipfsResult = await fetchCertificateFromIPFS(certId);
          if (ipfsResult['success']) {
            final data = ipfsResult['data'];
            final bool isNameMatch = data['name'].toString().toLowerCase() == studentName.toLowerCase();
            final bool isCertIdMatch = data['certificateId'].toString() == certId;

            if (isNameMatch && isCertIdMatch) {
              _certificateName = data['name'];
              _certificateIssuer = data['issuer'];
              _certificateId = certId;
              _certificateDate = data['date'];
              _certificateProgram = data['program'];
              verificationResult = _handleVerificationResult(
                true,
                'This certificate is authentic',
                certId,
                type,
                name: data['name'],
                issuer: data['issuer'],
                date: data['date'],
                program: data['program'],
              );
              await _recordVerificationResult(
                isSuccess: true,
                certificateId: certId,
                type: type,
                studentName: studentName,
                message: 'Certificate is authentic',
                details: data,
              );
            } else if (isCertIdMatch && !isNameMatch) {
              verificationResult = _handleVerificationResult(
                false,
                'Certificate is counterfeit. Student name does not match.',
                certId,
                type,
                expectedName: data['name'],
              );
              await _recordVerificationResult(
                isSuccess: false,
                certificateId: certId,
                type: type,
                studentName: studentName,
                message: 'Certificate is counterfeit. Student name does not match.',
                details: {'expectedName': data['name']},
              );
            } else {
              verificationResult = _handleVerificationResult(
                false,
                'Certificate is counterfeit',
                certId,
                type,
              );
              await _recordVerificationResult(
                isSuccess: false,
                certificateId: certId,
                type: type,
                studentName: studentName,
                message: 'Certificate is counterfeit',
              );
            }
          } else {
            verificationResult = _handleVerificationResult(
              false,
              ipfsResult['message'],
              certId,
              type,
            );
            await _recordVerificationResult(
              isSuccess: false,
              certificateId: certId,
              type: type,
              message: ipfsResult['message'],
            );
          }
        } else {
          final response = await http.post(
            Uri.parse('http://IP ADDRESS/block_cert/verify_cert.php'),
            body: {
              'certificate_id': certId,
              'student_name': studentName,
            },
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            bool isCertIdMatch = data['certificate_exists'] == true;
            bool isNameMatch = data['name_matches'] == true;

            if (isCertIdMatch && isNameMatch) {
              _certificateName = data['name'];
              _certificateIssuer = data['issuer'];
              _certificateId = certId;
              _certificateDate = data['date'];
              _certificateProgram = data['program'];
              verificationResult = _handleVerificationResult(
                true,
                'This certificate is authentic',
                certId,
                type,
                name: data['name'],
                issuer: data['issuer'],
                date: data['date'],
                program: data['program'],
              );
              await _recordVerificationResult(
                isSuccess: true,
                certificateId: certId,
                type: type,
                studentName: studentName,
                message: 'Certificate is authentic',
                details: data,
              );
            } else if (isCertIdMatch && !isNameMatch) {
              verificationResult = _handleVerificationResult(
                false,
                'Certificate is counterfeit. Student name does not match.',
                certId,
                type,
                expectedName: data['name'],
              );
              await _recordVerificationResult(
                isSuccess: false,
                certificateId: certId,
                type: type,
                studentName: studentName,
                message: 'Certificate is counterfeit. Student name does not match.',
                details: {'expectedName': data['name']},
              );
            } else {
              verificationResult = _handleVerificationResult(
                false,
                'Certificate is counterfeit',
                certId,
                type,
              );
              await _recordVerificationResult(
                isSuccess: false,
                certificateId: certId,
                type: type,
                studentName: studentName,
                message: 'Certificate is counterfeit',
              );
            }
          } else {
            verificationResult = _handleVerificationResult(
              false,
              'Server error: ${response.statusCode}',
              certId,
              type,
            );
            await _recordVerificationResult(
              isSuccess: false,
              certificateId: certId,
              type: type,
              message: 'Server error: ${response.statusCode}',
            );
          }
        }
      }
      // Send the verification result to the dashboard
      if (Navigator.of(context).canPop() && verificationResult != null) {
        Navigator.of(context).pop(verificationResult);
      }
    } catch (e) {
      final result = _handleVerificationResult(
        false,
        '❌ Verification failed: ${e.toString()}',
        certId,
        type,
      );
      if (Navigator.of(context).canPop() && result != null) {
        Navigator.of(context).pop(result);
      }
      await _recordVerificationResult(
        isSuccess: false,
        certificateId: certId,
        type: type,
        message: 'Verification failed: ${e.toString()}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? _handleVerificationResult(
      bool isSuccess,
      String message,
      String id,
      String type, {
        String? name,
        String? issuer,
        String? date,
        String? program,
        String? expectedName,
      }) {
    setState(() {
      _verificationSuccess = isSuccess;
      _verificationMessage = message;
      _isVerificationComplete = true;
    });

    String displayMessage = message;
    if (isSuccess) {
      displayMessage = '''
 ✅ Certificate is Authentic

  Student Name: ${name ?? 'N/A'}
  Certificate ID: $id
  Issuer: ${issuer ?? 'N/A'}
  Program: ${program ?? 'N/A'}
  Date Issued: ${date ?? 'N/A'}
  ''';
    } else if (expectedName != null) {
      displayMessage = '''
  ❌ $message

  Expected Name: $expectedName
  Entered Name: ${studentNameController.text}
  Certificate ID: $id
  ''';
    } else {
      displayMessage = '''
  ❌ $message

  Certificate ID: $id
  ''';
    }

    _showResultDialog(
      isSuccess ? 'Verification Successful' : 'Verification Failed',
      displayMessage,
    );
    // Return data
    return {
      'isSuccess': isSuccess,
      'message': message,
      'id': id,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      'details': {
        'name': name,
        'issuer': issuer,
        'date': date,
        'program': program,
      },
    };
  }

  bool _verifyTranscriptSignature(PlatformFile file) {
    return file.name.toLowerCase().contains("signed");
  }

  Future<void> _uploadTranscript() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'docx'],
      );

      if (result != null && mounted) {
        setState(() {
          uploadedTranscript = result.files.first;
          _isVerificationComplete = false;
        });
      }
    } catch (e) {
      _showResultDialog('Error', 'Failed to upload file: ${e.toString()}');
    }
  }

  Future<void> _navigateToQRScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRCodeScannerScreen()),
    );
    if (result != null && result is String && mounted) {
      setState(() {
        certificateIdController.text = result;
        _isVerificationComplete = false;
      });
    }
  }

  void _showResultDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearInputs() {
    setState(() {
      certificateIdController.clear();
      studentNameController.clear();
      uploadedTranscript = null;
      _isVerificationComplete = false;
    });
  }

  Widget _buildVerificationStatus() {
    if (!_isVerificationComplete) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: _verificationSuccess ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _verificationSuccess ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _verificationSuccess ? Icons.check_circle : Icons.error,
                color: _verificationSuccess ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _verificationMessage,
                  style: TextStyle(
                    color: _verificationSuccess ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ),
            ],
          ),
          if (_verificationSuccess && _certificateName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Name: $_certificateName',
              style: TextStyle(
                color: _verificationSuccess ? Colors.green[800] : Colors.red[800],
                fontSize: 14,
              ),
            ),
          ],
          if (_verificationSuccess && _certificateIssuer != null)
            Text(
              'Issuer: $_certificateIssuer',
              style: TextStyle(
                color: _verificationSuccess ? Colors.green[800] : Colors.red[800],
                fontSize: 14,
              ),
            ),
          if (_verificationSuccess && _certificateDate != null)
            Text(
              'Date: $_certificateDate',
              style: TextStyle(
                color: _verificationSuccess ? Colors.green[800] : Colors.red[800],
                fontSize: 14,
              ),
            ),
          if (_verificationSuccess && _certificateProgram != null)
            Text(
              'Program: $_certificateProgram',
              style: TextStyle(
                color: _verificationSuccess ? Colors.green[800] : Colors.red[800],
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _buildThemeData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Certificate Verification"),
          actions: [
            if (certificateIdController.text.isNotEmpty ||
                studentNameController.text.isNotEmpty ||
                uploadedTranscript != null)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearInputs,
                tooltip: 'Clear inputs',
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              TextField(
                controller: certificateIdController,
                decoration: InputDecoration(
                  labelText: 'Certificate ID',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _navigateToQRScanner,
                    tooltip: 'Scan QR Code',
                  ),
                ),
                onChanged: (_) => setState(() {
                  _isVerificationComplete = false;
                }),
              ),
              const SizedBox(height: 20),
              if (uploadedTranscript == null)
                TextField(
                  controller: studentNameController,
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                  ),
                  onChanged: (_) => setState(() {
                    _isVerificationComplete = false;
                  }),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _uploadTranscript,
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Upload Transcript"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (uploadedTranscript != null)
                    Expanded(
                      flex: 2,
                      child: Text(
                        uploadedTranscript!.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              _buildVerificationStatus(),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _verify,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 15),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: const Text('Verify'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
