import 'package:timeago/timeago.dart' as timeago;

class TimeUtils {
  static String format(DateTime dt) => timeago.format(dt, allowFromNow: true);

  static String formatFull(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
