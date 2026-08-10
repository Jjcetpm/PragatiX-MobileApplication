class Student {
  final int id;
  final String name;
  final String regNo;
  final String dept;
  final int score;

  Student({
    required this.id,
    required this.name,
    required this.regNo,
    required this.dept,
    required this.score,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      regNo: json['regNo'],
      dept: json['dept'],
      score: json['score'],
    );
  }
}
