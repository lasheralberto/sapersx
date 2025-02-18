
import 'package:sapers/models/user.dart';

class UserCacheManager {
  static final Map<String, UserInfoPopUp> _userCache = {};

  static UserInfoPopUp? getCachedUser(String username) => _userCache[username];

  static void cacheUser(String username, UserInfoPopUp user) {
    _userCache[username] = user;
  }
}