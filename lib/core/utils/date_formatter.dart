class DateFormatter {
  static String lastSeen(DateTime time) {
    final diff = DateTime.now().difference(time);
    if(diff.inSeconds < 60) return 'just now';
    if(diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if(diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static String timeOnly(DateTime time) {
    final h = time.hour.toString().padLeft(2,'0');
    final m = time.minute.toString().padLeft(2,'0');
    return '$h:$m';
  }
}