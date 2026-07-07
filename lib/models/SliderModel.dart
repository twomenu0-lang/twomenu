class SliderModel {
  String? image;
  String? thumb;
  String? url;
  String? desc;
  String? title;

  SliderModel({this.image, this.thumb, this.url, this.desc,this.title});

  factory SliderModel.fromJson(Map<String, dynamic> json) {
    return SliderModel(
      image: json['image'],
      thumb: json['thumb'],
      url: json['url'],
      desc: json['desc'],
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['image'] = image;
    data['thumb'] = thumb;
    data['url'] = url;
    data['desc'] = desc;
    data['title'] = title;
    return data;
  }
}

