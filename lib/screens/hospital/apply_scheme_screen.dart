import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApplySchemeScreen extends StatefulWidget {
  const ApplySchemeScreen({super.key});

  @override
  _ApplySchemeScreenState createState() => _ApplySchemeScreenState();
}

class _ApplySchemeScreenState extends State<ApplySchemeScreen> {
  final aadhaarController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final dobController = TextEditingController();
  final genderController = TextEditingController();
  final permanent_addressController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _secureStorage = const FlutterSecureStorage();

  String? selectedScheme;
  List<String> schemes = [];

  Future<void> fetchSchemes() async {
    try {
      final response = await Supabase.instance.client
          .from('schemes') // Table name
          .select('scheme_name');

      setState(() {
        schemes = List<String>.from((response as List<dynamic>)
            .map((row) => row['scheme_name'].toString()));
      });
    } catch (e) {
      print('Error fetching schemes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching schemes: $e')),
      );
    }
  }

  Future<void> fetchAndFillData() async {
    final aadhaar = aadhaarController.text;
    if (aadhaar.isEmpty || aadhaar.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid Aadhaar number')),
      );
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('patients')
          .select('name, phone_no, dob, gender, address')
          .eq('aadhaar_no', aadhaar)
          .maybeSingle();

      // ignore: unnecessary_null_comparison
      if (response != null) {
        setState(() {
          nameController.text = response['name'] ?? '';
          phoneController.text = response['phone_no'] ?? '';
          dobController.text = response['dob'] ?? '';
          genderController.text = response['gender'] ?? '';
          permanent_addressController.text = response['address'] ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No patient data found')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // If validation fails, stop submission.
      return;
    }

    try {
      // Step 1: Fetch the user ID from secure storage.
      final userId = await _secureStorage.read(key: 'userId');
      if (userId == null) {
        throw Exception('User ID not found in secure storage');
      }

      // Step 2: Retrieve `sub_dist`, `dist`, and `state` from the `hospitals` table.
      final hospitalResponse = await Supabase.instance.client
          .from('hospitals')
          .select('sub_dist, dist, state')
          .eq('id', userId)
          .single();

      final subDistrict = hospitalResponse['sub_dist'] ?? '';
      final district = hospitalResponse['dist'] ?? '';
      final state = hospitalResponse['state'] ?? '';

      final response =
          await Supabase.instance.client.from('applied_schemes').insert({
        'aadhaar_no': aadhaarController.text,
        'name': nameController.text,
        'phone_no': phoneController.text,
        'dob': dobController.text,
        'gender': genderController.text,
        'address': permanent_addressController.text,
        'scheme_name': selectedScheme,
        'sub_dist': subDistrict,
        'dist': district,
        'state': state,
      });

      if (response is PostgrestException) {
        throw Exception(response.message);
      }

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Registration Successful'),
            content: const Text(
                'Your request has been sent to the sub-district admin. They will review your details and respond to you via email.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  _clearTextfield();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error submitting form: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting form: $e')),
      );
    }
  }

  void _clearTextfield() {
    setState(() {
      selectedScheme = null;
    });

    nameController.clear();
    aadhaarController.clear();
    phoneController.clear();
    dobController.clear();
    genderController.clear();
    permanent_addressController.clear();
  }

  @override
  void initState() {
    super.initState();
    fetchSchemes(); // Fetch schemes on screen load
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Scheme',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedScheme,
                  items: schemes
                      .map((scheme) => DropdownMenuItem<String>(
                            value: scheme,
                            child: Text(scheme),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedScheme = value;
                    });
                    if (_formKey.currentState != null) {
                      _formKey.currentState!.validate();
                    }
                  },
                  validator: (value) =>
                      value == null ? 'Please select a scheme' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: aadhaarController,
                  decoration: const InputDecoration(
                    labelText: 'Aadhaar Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Aadhaar number';
                    } else if (value.length != 12 ||
                        !RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Enter a valid 12-digit Aadhaar number';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (_formKey.currentState != null) {
                      _formKey.currentState!.validate();
                    }
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: fetchAndFillData,
                  child: const Text('Fetch Details'),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  enabled: false,
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  enabled: false,
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: dobController,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  enabled: false,
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: genderController,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  enabled: false,
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: permanent_addressController,
                  decoration: const InputDecoration(
                    labelText: 'Permanent address',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  enabled: false,
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: submitForm,
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    aadhaarController.dispose();
    phoneController.dispose();
    dobController.dispose();
    genderController.dispose();
    permanent_addressController.dispose();
    super.dispose();
  }
}
