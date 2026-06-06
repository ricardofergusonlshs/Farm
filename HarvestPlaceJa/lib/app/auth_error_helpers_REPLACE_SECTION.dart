bool isNetworkAuthFailure(Object error) {
  final lower = error.toString().toLowerCase();

  return lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('connection refused') ||
      lower.contains('connection reset') ||
      lower.contains('connection timed out') ||
      lower.contains('network is unreachable') ||
      lower.contains('network error') ||
      lower.contains('clientexception') ||
      lower.contains('handshakeexception') ||
      lower.contains('xmlhttprequest error') ||
      lower.contains('no address associated with hostname') ||
      lower.contains('software caused connection abort');
}

String friendlyAuthErrorMessage(
  AuthException error, {
  required bool isRegister,
}) {
  final message = error.message.trim();
  final lower = message.toLowerCase();

  if (isNetworkAuthFailure(error)) {
    return 'Connection problem. Please check your internet and try again.';
  }

  if (lower.contains('invalid login credentials') ||
      lower.contains('invalid credentials') ||
      lower.contains('invalid email or password')) {
    return 'Incorrect email or password.';
  }

  if (lower.contains('email not confirmed') ||
      lower.contains('confirm your email')) {
    return 'Please confirm this email address before signing in.';
  }

  if (lower.contains('rate limit') ||
      lower.contains('over_email_send_rate_limit') ||
      lower.contains('too many')) {
    return 'Too many attempts. Please wait a few minutes, then try again.';
  }

  if (message.isNotEmpty &&
      message.length <= 120 &&
      !lower.contains('supabase') &&
      !lower.contains('postgrest') &&
      !lower.contains('exception')) {
    return isRegister
        ? 'Could not create account: $message'
        : 'Could not sign in: $message';
  }

  return isRegister
      ? 'Could not create account. Please check your details and try again.'
      : 'Could not sign in. Please check your email and password.';
}

String friendlyUnexpectedAuthError(
  Object error, {
  required bool isRegister,
}) {
  if (isNetworkAuthFailure(error)) {
    return 'Connection problem. Please check your internet and try again.';
  }

  return isRegister
      ? 'Could not create account. Please check your details and try again.'
      : 'Could not sign in. Please check your email and password.';
}
