import 'dart:math';

import '../../core/constants/app_config.dart';


abstract final class CodeGenerator {
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String generate() {
    final random = Random.secure();
    final length = AppConfig.inviteCodelength;
    final buffer = StringBuffer();
    for(var i =0; i<length; i++){
      buffer.write(_alphabet[random.nextInt(_alphabet.length)]);
    }
    return buffer.toString();
  }
}