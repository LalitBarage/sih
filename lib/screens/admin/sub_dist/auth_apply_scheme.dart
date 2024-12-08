import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class AuthApplyScheme extends StatefulWidget {
  const AuthApplyScheme({super.key});

  @override
  _AuthApplySchemeState createState() => _AuthApplySchemeState();
}

class _AuthApplySchemeState extends State<AuthApplyScheme> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _appliedSchemes = [];
  bool _isLoading = false;
  final _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchSchemes();
  }

  Future<void> _fetchSchemes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Retrieve admin ID from secure storage
      final adminId = await _secureStorage.read(key: 'adminId');
      if (adminId == null) {
        _showError("Admin ID not found. Please log in again.");
        return;
      }

      // Fetch admin's sub_district based on admin ID
      final adminResponse = await _supabase
          .from('admin')
          .select('sub_dist')
          .eq('id', adminId)
          .single();

      if (adminResponse['sub_dist'] == null) {
        _showError("Admin data not found.");
        return;
      }

      final adminSubDist = adminResponse['sub_dist'];
      final response = await _supabase
          .from('applied_schemes')
          .select()
          .eq('sub_dist', adminSubDist)
          .eq('status', false);

      setState(() {
        _appliedSchemes = (response as List<dynamic>)
            .map((hospital) => hospital as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      _showError("Error fetching data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifySchemes(int id) async {
    try {
      // Supabase query
      final supabaseResponse = await _supabase
          .from('applied_schemes')
          .update({'status': true})
          .eq('id', id)
          .select('phone_no');

      if (supabaseResponse.isNotEmpty) {
        final phoneNo = supabaseResponse[0]['phone_no'];
        final fullPhoneNo = '+91$phoneNo';
        print(fullPhoneNo);

        // Send SMS using Twilio
        const accountSid =
            'AC3cdaec33a058556db5e2cb6457de79da'; // Replace with your Twilio Account SID
        const authToken =
            'f8e7881f68241ea146b8ee64ffada91c'; // Replace with your Twilio Auth Token
        const fromPhoneNumber =
            '+17754588201'; // Replace with your Twilio phone number

        final twilioUrl =
            'https://api.twilio.com/2010-04-01/Accounts/AC3cdaec33a058556db5e2cb6457de79da/Messages.json';

        final twilioResponse = await http.post(
          Uri.parse(twilioUrl),
          headers: {
            'Authorization':
                'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}',
          },
          body: {
            'To': fullPhoneNo,
            'From': fromPhoneNumber,
            'Body': 'Your request to apply scheme is succesfully verified!',
          },
        );

        if (twilioResponse.statusCode == 201) {
          print('SMS sent successfully to $phoneNo!');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SMS sent successfully!')),
          );
        } else {
          print(
              'Failed to send SMS. Status code: ${twilioResponse.statusCode}');
          print('Response body: ${twilioResponse.body}');
        }
      } else {
        print('No phone number found.');
      }

      _fetchSchemes(); // Refresh the list
    } catch (e) {
      _showError("Error verifying hospital: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $message')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: _appliedSchemes.length,
                itemBuilder: (context, index) {
                  final request = _appliedSchemes[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(request['name'] ?? 'Unknown Name'),
                          const Spacer(),
                          const SizedBox(width: 5),
                          ElevatedButton(
                            onPressed: () => _verifySchemes(request['id']),
                            child: const Text('Verify'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
