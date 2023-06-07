import 'package:flutter_emoji/flutter_emoji.dart';

class Emoji {
  ///
  /// If emoji not found, the parser always returns this.
  ///
  static final Emoji None = Emoji(EmojiConst.charEmpty, EmojiConst.charEmpty);

  final String name;
  final String code;

  Emoji(this.name, this.code);

  String get full => EmojiUtil.ensureColons(name);

  @override
  bool operator ==(other) {
    return other is Emoji && name == other.name && code == other.code;
  }

  Emoji clone() {
    return Emoji(name, code);
  }

  @override
  String toString() {
    return 'Emoji{name="$name", full="$full", code="$code"}';
  }
}
