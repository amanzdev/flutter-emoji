library flutter_emoji;

import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:http/http.dart' as http;

///
/// Constants defined for Emoji.
///
class EmojiConst {
  static final String charNonSpacingMark = String.fromCharCode(0xfe0f);
  static final String charColon = ':';
  static final String charEmpty = '';
}

/// List of pre-defined message used in this library
class EmojiMessage {
  static final String errorMalformedEmojiName = 'Malformed emoji name';
}

///
/// Utilities to handle emoji operations.
///
class EmojiUtil {
  ///
  /// Strip colons for emoji name.
  /// So, ':heart:' will become 'heart'.
  ///
  static String? stripColons(String? name,
      [void Function(String message)? onError]) {
    if (name == null) {
      return null;
    }
    Iterable<Match> matches = EmojiParser.REGEX_NAME.allMatches(name);
    if (matches.isEmpty) {
      if (onError != null) {
        onError(EmojiMessage.errorMalformedEmojiName);
      }
      return name;
    }
    return name.replaceAll(EmojiConst.charColon, EmojiConst.charEmpty);
  }

  ///
  /// Wrap colons on both sides of emoji name.
  /// So, 'heart' will become ':heart:'.
  ///
  static String ensureColons(String name) {
    var res = name;
    if ('${name[0]}' != EmojiConst.charColon) {
      res = EmojiConst.charColon + name;
    }

    if (!name.endsWith(EmojiConst.charColon)) {
      res += EmojiConst.charColon;
    }

    return res;
  }

  ///
  /// When processing emojis, we don't need to store the graphical byte
  /// which is 0xfe0f, or so-called 'Non-Spacing Mark'.
  ///
  static String? stripNSM(String? name) => name?.replaceAll(
      RegExp(EmojiConst.charNonSpacingMark), EmojiConst.charEmpty);
}

///
/// The representation of an emoji.
/// There are three properties availables:
///   - 'name' : the emoji name (no colon)
///   - 'full' : the full emoji name. It is name with colons on both sides.
///   - 'code' : the actual graphic presentation of emoji.
///
/// Emoji.None is being used to represent a NULL emoji.
///
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

///
/// Emoji storage and parser.
/// You will need to instantiate one of this instance to start using.
///
class EmojiParser {
  ///
  /// This regex is insane, borrowed from lodash, a Javascript library.
  ///
  /// Reference: https://github.com/lodash/lodash/blob/4.16.6/lodash.js#L242
  ///
//  static final RegExp REGEX_EMOJI = RegExp(
//      r'(?:[\u2700-\u27bf]|(?:\ud83c[\udde6-\uddff]){2}|[\ud800-\udbff][\udc00-\udfff])[\ufe0e\ufe0f]?(?:[\u0300-\u036f\ufe20-\ufe23\u20d0-\u20f0]|\ud83c[\udffb-\udfff])?(?:\u200d(?:[^\ud800-\udfff]|(?:\ud83c[\udde6-\uddff]){2}|[\ud800-\udbff][\udc00-\udfff])[\ufe0e\ufe0f]?(?:[\u0300-\u036f\ufe20-\ufe23\u20d0-\u20f0]|\ud83c[\udffb-\udfff])?)*');

  /// A tweak regexp to pass all Emoji Unicode 11.0
  /// TODO: improve this version, since it does not match the graphical bytes.
  static final RegExp REGEX_EMOJI = RegExp(
      r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])');

  static final RegExp REGEX_NAME = RegExp(r':([\w-+]+):');

  final Map<String, Emoji> _emojisByName = <String, Emoji>{};
  final Map<String?, Emoji> _emojisByCode = <String, Emoji>{};

  EmojiParser({bool init: true}) {
    if (init == true) {
      initLocalData();
    }
  }
  void initLocalData() {
    _init(JSON_EMOJI);
  }

  Future<void> initServerData() async {
    final response = await http.get(Uri.parse(EMOJI_SOURCE));
    _init(response.body);
  }

  void _init(String dataset) {
    Map<String, dynamic> mapEmojis = jsonDecode(dataset);
    mapEmojis.forEach((k, v) {
      _emojisByName[v] = Emoji(v[0], k);
      _emojisByCode[EmojiUtil.stripNSM(k)] = Emoji(v[0], k);
    });
  }

  Emoji get(String? name) => _emojisByName[EmojiUtil.stripColons(name)] ?? Emoji.None;

  Emoji getName(String? name) => get(name);
  bool hasName(String name) =>
      _emojisByName.containsKey(EmojiUtil.stripColons(name));

  ///
  /// Get info for an emoji.
  ///
  /// For example:
  ///
  ///   var parser = EmojiParser();
  ///   var emojiHeart = parser.info('heart');
  ///   print(emojiHeart); '{name: heart, full: :heart:, emoji: ❤️}'
  ///
  /// Returns Emoji.None if not found.
  ///
  Emoji info(String name) {
    return hasName(name) ? get(name) : Emoji.None;
  }

  ///
  /// Get emoji based on emoji code.
  ///
  /// For example:
  ///
  ///   var parser = EmojiParser();
  ///   var emojiHeart = parser.getEmoji('❤');
  ///   print(emojiHeart); '{name: heart, full: :heart:, emoji: ❤️}'
  ///
  /// Returns Emoji.None if not found.
  ///
  Emoji getEmoji(String? emoji) {
    return _emojisByCode[EmojiUtil.stripNSM(emoji)] ?? Emoji.None;
  }

  bool hasEmoji(String? emoji) {
    return _emojisByCode.containsKey(EmojiUtil.stripNSM(emoji));
  }

  ///
  /// Emojify the input text.
  ///
  /// For example: 'I :heart: :coffee:' => 'I ❤️ ☕'
  ///
  String emojify(String text, {String Function(String)? fnFormat}) {
    Iterable<Match> matches = REGEX_NAME.allMatches(text);
    if (matches.isNotEmpty) {
      var result = text;
      for (Match m in matches) {
        var _e = EmojiUtil.stripColons(m.group(0));
        if (_e == null || m.group(0) == null) continue;
        if (hasName(_e)) {
          var pattern = RegExp.escape(m.group(0)!);
          var formattedCode = get(_e).code;
          if (fnFormat != null) {
            formattedCode = fnFormat(formattedCode);
          }
          result =
              result.replaceAll(RegExp(pattern, unicode: true), formattedCode);
        }
      }
      return result;
    }
    return text;
  }

  ///
  /// This method will unemojify the text containing the Unicode emoji symbols
  /// into emoji name.
  ///
  /// For example: 'I ❤️ Flutter' => 'I :heart: Flutter'
  ///
  String unemojify(String text) {
    if (text.isEmpty) return text;

    final characters = Characters(text);
    final buffer = StringBuffer();
    for (final character in characters) {
      if (hasEmoji(character)) {
        var result = character;
        result = result.replaceAll(
          character,
          getEmoji(character).full,
        );

        buffer.write(result);
      } else {
        buffer.write(character);
      }
    }
    return buffer.toString();
  }

  ///
  /// Count number of emoji containing in the text.
  ///
  /// For example: count('I ❤️ Flutter just like ☕') = 2
  int count(String text) {
    if (text.isEmpty) return 0;

    int cnt = 0;
    for (final character in text.characters) {
      if (hasEmoji(character)) {
        cnt++;
      }
    }
    return cnt;
  }

  ///
  /// Count frequency of emoji containing in the text.
  ///
  /// For example: frequency('I ❤️ Flutter just like ☕', '❤️') = 1
  ///
  int frequency(String text, String symbol) {
    if (text.isEmpty) return 0;

    int cnt = 0;
    for (final character in text.characters) {
      if (character == symbol) {
        cnt++;
      }
    }
    return cnt;
  }

  ///
  /// Replace an emoji by another emoji.
  ///
  /// For example: replace('I ❤️ coffee', '❤️', '❤️‍🔥') => 'I ❤️‍🔥 coffee'
  ///
  String? replace(String text, String fromSymbol, String toSymbol) {
    if (text.isEmpty) return null;

    final buffer = StringBuffer();
    for (final character in text.characters) {
      if (character == fromSymbol) {
        buffer.write(toSymbol);
      } else {
        buffer.write(character);
      }
    }
    return buffer.toString();
  }

  ///
  /// Return a list of emojis found in the input text
  ///
  /// For example: parseEmojis('I ❤️ Flutter just like ☕') => ['❤️', '☕']
  ///
  List<String> parseEmojis(String text) {
    if (text.isEmpty) return List.empty();

    List<String> result = <String>[];
    for (final character in text.characters) {
      if (hasEmoji(character)) {
        result.add(character);
      }
    }
    return result;
  }
}
