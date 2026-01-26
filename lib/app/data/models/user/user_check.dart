class UserCheck {
  UserCheck({
      this.success, 
      this.data, 
      this.hasUsername,
  });

  UserCheck.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    hasUsername = json['hasUsername'];
  }
  bool? success;
  Data? data;
  bool? hasUsername;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    map['hasUsername'] = hasUsername;
    return map;
  }

}

class Data {
  Data({
      this.name, 
      this.username, 
      this.avatar, 
      this.isActive,});

  Data.fromJson(dynamic json) {
    name = json['name'];
    username = json['username'];
    avatar = json['avatar'];
    isActive = json['isActive'];
  }
  String? name;
  String? username;
  String? avatar;
  bool? isActive;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['username'] = username;
    map['avatar'] = avatar;
    map['isActive'] = isActive;
    return map;
  }

}