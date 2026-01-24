class CreateProfile {
  CreateProfile({
      this.success, 
      this.message, 
      this.user,});

  CreateProfile.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }
  bool? success;
  String? message;
  User? user;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
    if (user != null) {
      map['user'] = user?.toJson();
    }
    return map;
  }

}

class User {
  User({
      this.uid, 
      this.name, 
      this.email, 
      this.phone, 
      this.role, 
      this.avatar, 
      this.bio,
      this.counts, 
      this.settings, 
      this.status, 
      this.metadata,});

  User.fromJson(dynamic json) {
    uid = json['uid'];
    name = json['name'];
    email = json['email'];
    phone = json['phone'];
    role = json['role'];
    avatar = json['avatar'] != null ? Avatar.fromJson(json['avatar']) : null;
    bio = json['bio'];
    counts = json['counts'] != null ? Counts.fromJson(json['counts']) : null;
    settings = json['settings'] != null ? Settings.fromJson(json['settings']) : null;
    status = json['status'] != null ? Status.fromJson(json['status']) : null;
    metadata = json['metadata'] != null ? Metadata.fromJson(json['metadata']) : null;
  }
  String? uid;
  String? name;
  String? email;
  String? phone;
  String? role;
  Avatar? avatar;
  String? bio;
  Counts? counts;
  Settings? settings;
  Status? status;
  Metadata? metadata;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['uid'] = uid;
    map['name'] = name;
    map['email'] = email;
    map['phone'] = phone;
    map['role'] = role;
    if (avatar != null) {
      map['avatar'] = avatar?.toJson();
    }
    map['bio'] = bio;
    if (counts != null) {
      map['counts'] = counts?.toJson();
    }
    if (settings != null) {
      map['settings'] = settings?.toJson();
    }
    if (status != null) {
      map['status'] = status?.toJson();
    }
    if (metadata != null) {
      map['metadata'] = metadata?.toJson();
    }
    return map;
  }

}

class Metadata {
  Metadata({
      this.deleted, 
      this.deletedAt, 
      this.createdAt, 
      this.updatedAt,});

  Metadata.fromJson(dynamic json) {
    deleted = json['deleted'];
    deletedAt = json['deletedAt'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }
  bool? deleted;
  dynamic deletedAt;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['deleted'] = deleted;
    map['deletedAt'] = deletedAt;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    return map;
  }

}

class Status {
  Status({
      this.isOnline, 
      this.lastSeen,});

  Status.fromJson(dynamic json) {
    isOnline = json['isOnline'];
    lastSeen = json['lastSeen'];
  }
  bool? isOnline;
  String? lastSeen;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['isOnline'] = isOnline;
    map['lastSeen'] = lastSeen;
    return map;
  }

}

class Settings {
  Settings({
      this.isPrivate, 
      this.notifications,});

  Settings.fromJson(dynamic json) {
    isPrivate = json['isPrivate'];
    notifications = json['notifications'];
  }
  bool? isPrivate;
  bool? notifications;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['isPrivate'] = isPrivate;
    map['notifications'] = notifications;
    return map;
  }

}

class Counts {
  Counts({
      this.followers, 
      this.following, 
      this.posts,});

  Counts.fromJson(dynamic json) {
    followers = json['followers'];
    following = json['following'];
    posts = json['posts'];
  }
  num? followers;
  num? following;
  num? posts;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['followers'] = followers;
    map['following'] = following;
    map['posts'] = posts;
    return map;
  }

}

class Avatar {
  Avatar({
      this.url, 
      this.fileId,});

  Avatar.fromJson(dynamic json) {
    url = json['url'];
    fileId = json['fileId'];
  }
  String? url;
  String? fileId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['url'] = url;
    map['fileId'] = fileId;
    return map;
  }

}