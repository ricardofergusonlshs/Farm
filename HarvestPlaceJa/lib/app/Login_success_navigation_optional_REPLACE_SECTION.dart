// Optional replacement inside LoginScreen.submit() success navigation.
// Use this only if Home still says Guest after a successful login.

if (widget.returnToPrevious) {
  Navigator.of(context).pop(true);
} else {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => MainNavigation(
        key: ValueKey(
          'main-${supabase.auth.currentUser?.id ?? DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    ),
    (route) => false,
  );
}
