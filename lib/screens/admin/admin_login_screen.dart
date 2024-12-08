import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sih/screens/admin/dist_state/ds_admin_main.dart';
import 'package:sih/screens/admin/sub_dist/admin_main_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _secureStorage = const FlutterSecureStorage();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        final supabase = Supabase.instance.client;

        // Query the database for the admin with the given email
        final response = await supabase
            .from('admin')
            .select('password, id, role')
            .eq('email', email)
            .maybeSingle();

        if (response == null) {
          // No admin found with that email
          _showErrorDialog("No admin detail found with that email.");
          return;
        }

        final dbPassword = response['password'];
        final role = response['role'];

        if (password == dbPassword) {
          // Save admin ID in secure storage
          await _secureStorage.write(
              key: 'adminId', value: response['id'].toString());

          // Login successful
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login successful!')),
          );

          // Navigate based on role
          if (role == 'sub_dist') {
            await _secureStorage.write(
                key: 'adminId', value: response['id'].toString());
            await _secureStorage.write(
                key: 'role', value: response['role'].toString());
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminMainScreen(),
              ), // Replace with Sub-Dist role screen
              (route) => false,
            );
          } else if (role == 'dist' || role == 'state') {
            await _secureStorage.write(
                key: 'adminId', value: response['id'].toString());
            await _secureStorage.write(
                key: 'role', value: response['role'].toString());
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const DsAdminMain(),
              ), // Replace with Dist/State role screen
              (route) => false,
            );
          } else {
            _showErrorDialog("Invalid role assigned.");
          }
        } else {
          // Password mismatch
          _showErrorDialog("Invalid email or password.");
        }
      } catch (error) {
        // Handle any errors (e.g., network issues, Supabase query errors)
        _showErrorDialog('An error occurred: ${error.toString()}');
      }
    }
  }

  // Function to show an error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Login Failed'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Login'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
