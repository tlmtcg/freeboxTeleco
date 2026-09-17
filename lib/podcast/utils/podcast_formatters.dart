class PodcastFormatters {
  PodcastFormatters._();

  static String duration(Duration duration) {
    final hours = duration.inHours;

    final minutes = duration.inMinutes.remainder(60);

    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '$minutes:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  static String durationShort(Duration duration) {
    final hours = duration.inHours;

    final minutes = duration.inMinutes.remainder(60);

    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h '
          '${minutes.toString().padLeft(2, '0')}min';
    }

    if (minutes > 0) {
      return '${minutes}min '
          '${seconds.toString().padLeft(2, '0')}s';
    }

    return '${seconds}s';
  }

  static String date(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}
