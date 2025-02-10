import "package:flutter/material.dart";
import "package:mvvm_starter/auth/signup_view_model.dart";
import "package:mvvm_starter/auth/user_service.dart";
import "package:mvvm_starter/core/database_view.dart";
import "package:mvvm_starter/core/locator.dart";

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _CreateAccountViewState();
}

class _CreateAccountViewState extends State<SignUpView> {
  late final SignupViewModel createAccountViewModel;
  late final TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    createAccountViewModel = SignupViewModel(locator<UserService>());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Create Account Lesson"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DatabasePage(),
                ),
              );
            },
            child: const Text("Show Database"),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            spacing: 8,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Name",
                ),
                controller: nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a name";
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    final userCreated =
                        createAccountViewModel.createUser(nameController.text);

                    if (userCreated == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("User not created"),
                        ),
                      );
                      return;
                    }

                    nameController.clear();
                    if (userCreated.isAdmin == 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Admin user created, click database viewer in top right to see users",
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "User created, click database viewer in top right to see users",
                          ),
                        ),
                      );
                    }
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter a name"),
                      ),
                    );
                  }
                },
                child: const Text("Create Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
