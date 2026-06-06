class LoginScreen extends StatefulWidget {
  final bool returnToPrevious;
  final bool startInRegister;

  const LoginScreen({
    super.key,
    this.returnToPrevious = false,
    this.startInRegister = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();

  bool loading = false;
  bool isRegister = false;
  String selectedRole = 'customer';

  @override
  void initState() {
    super.initState();
    isRegister = widget.startInRegister;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;
    final fullName = fullNameController.text.trim();

    if (email.isEmpty ||
        password.trim().isEmpty ||
        (isRegister && fullName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => loading = true);

    try {
      if (isRegister) {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: AppConfig.emailConfirmationRedirectTo,
          data: {
            'full_name': fullName,
            'role': selectedRole,
          },
        );

        FarmDataCache.clearAll();

        if (!mounted) return;

        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created. Please check your email and tap the confirmation link before signing in.',
              ),
            ),
          );

          setState(() {
            isRegister = false;
            passwordController.clear();
          });
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created. You are signed in.')),
        );

        if (widget.returnToPrevious) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigation()),
            (route) => false,
          );
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        FarmDataCache.clearAll();

        if (!mounted) return;

        if (widget.returnToPrevious) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigation()),
            (route) => false,
          );
        }
      }
    } on AuthException catch (error) {
      if (!mounted) return;

      farmDebugLog('Supabase auth error: ${error.message}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyAuthErrorMessage(
              error,
              isRegister: isRegister,
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      farmDebugLog('Unexpected auth error: $error');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyUnexpectedAuthError(
              error,
              isRegister: isRegister,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;
    final keyboardOpen = keyboardBottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: FarmColors.background,
      appBar: widget.returnToPrevious
          ? AppBar(
              title: Text(isRegister ? 'Create Account' : 'Sign In'),
              backgroundColor: FarmColors.background,
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                22,
                keyboardOpen ? 14 : 22,
                22,
                22 + keyboardBottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: keyboardOpen ? 8 : 28),
                    if (!keyboardOpen) ...[
                      const HeroCard(),
                      const SizedBox(height: 26),
                    ],
                    Text(
                      isRegister ? 'Create your account' : 'Welcome back',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isRegister
                          ? 'Sign up as a customer.'
                          : 'Login to continue shopping fresh farm produce.',
                      style: const TextStyle(color: FarmColors.mutedText),
                    ),
                    const SizedBox(height: 22),
                    if (isRegister) ...[
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'customer',
                            icon: Icon(Icons.person_outline),
                            label: Text('Customer'),
                          ),
                          ButtonSegment(
                            value: 'farmer',
                            icon: Icon(Icons.agriculture_outlined),
                            label: Text('Farmer'),
                          ),
                        ],
                        selected: {selectedRole},
                        onSelectionChanged: loading
                            ? null
                            : (values) {
                                setState(() => selectedRole = values.first);
                              },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: fullNameController,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) {
                        if (!loading) submit();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    if (!isRegister) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.lock_reset_outlined, size: 18),
                          label: const Text('Forgot Password?'),
                          onPressed: loading
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ForgotPasswordScreen(
                                        initialEmail:
                                            emailController.text.trim(),
                                      ),
                                    ),
                                  );
                                },
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    PrimaryFarmButton(
                      label: loading
                          ? 'Please wait...'
                          : (isRegister ? 'Create Account' : 'Login'),
                      onPressed: loading ? null : submit,
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => setState(() => isRegister = !isRegister),
                      child: Text(
                        isRegister
                            ? 'Already have an account? Login'
                            : 'Create account',
                      ),
                    ),
                    const SizedBox(height: 24),
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
