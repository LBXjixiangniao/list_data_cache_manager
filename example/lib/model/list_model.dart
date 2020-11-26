class ListItemInfoModel {
  int value;

  ListItemInfoModel({
    this.value,
  });

  ListItemInfoModel.fromJson(Map<String, dynamic> json) {
    value = json['value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['value'] = this.value;

    return data;
  }
}
