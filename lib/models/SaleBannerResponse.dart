class Salebanner {
  String? title;
  String? startDate;
  String? endDate;
  String? image;
  String? thumb;

  Salebanner(
      {this.title,
        this.startDate,
        this.endDate,
        this.image,
        this.thumb});

  Salebanner.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    image = json['image'];
    thumb = json['thumb'];

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['image'] = image;
    data['thumb'] = thumb;
    return data;
  }
}
