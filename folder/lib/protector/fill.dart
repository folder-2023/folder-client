class Fill {
  final int? fillId;
  final String fillName;
  final String fillTime;
  bool fillCheck;

  Fill(
      {this.fillId,
      required this.fillName,
      required this.fillTime,
      this.fillCheck = false});

  factory Fill.fromJson(Map<String?, dynamic> json) {
    return Fill(
        fillId: json['fillId'],
        fillName: json['fillName'],
        fillTime: json['fillTime'],
        fillCheck: json['fillCheck']);
  }
}
