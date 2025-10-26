class DateFormatterWidget {
  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} روز پیش';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ساعت پیش';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} دقیقه پیش';
      } else {
        return 'همین الان';
      }
    } catch (e) {
      return dateString;
    }
  }

  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} روز پیش';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعت پیش';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقیقه پیش';
    } else {
      return 'همین الان';
    }
  }
}
