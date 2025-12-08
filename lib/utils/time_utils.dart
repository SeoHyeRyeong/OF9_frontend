class TimeUtils {
  /// createdAt 시간을 기준으로 "n초 전", "n분 전" 등으로 표시
  static String getTimeAgo(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return '';

    try {
      final DateTime createdTime = DateTime.parse(createdAt).toLocal();
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(createdTime);

      if (difference.inSeconds < 60) {
        return '${difference.inSeconds}초 전';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}분 전';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}시간 전';
      } else if (difference.inDays < 30) {
        return '${difference.inDays}일 전';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months개월 전';
      } else {
        return '오래 전';
      }
    } catch (e) {
      print('시간 파싱 오류: $e');
      return '';
    }
  }
}
