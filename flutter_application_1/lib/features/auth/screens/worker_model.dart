class Worker {
  final String name, job, rating, reviews, distance, imageUrl, char;
  final String? experience; // أضفنا علامة الاستفهام عشان يكون اختياري وما يضرب
  bool isSaved;

  Worker({
    required this.name,
    required this.job,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.imageUrl,
    required this.char,
    this.experience, // ممرر هنا كاختياري
    this.isSaved = false,
  });
}