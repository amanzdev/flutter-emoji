import 'package:flutter_emoji/emoji.dart';
import 'package:test/test.dart';
import 'package:flutter_emoji/flutter_emoji.dart';

void main() {
  var emojiParser = EmojiParser();
  var emojiFlagMalaysia = Emoji('flag_malaysia', '🇲🇾');
  var emojiHeart = Emoji('red_heart', '❤️');
  var emojiFlagUS = Emoji('flag-us', '🇺🇸'); // "flag-us":"🇺🇸"

  test('EmojiUtil.stripColons()', () {
    expect(EmojiUtil.stripColons('flag_malaysia'), 'flag_malaysia');
    expect(
        EmojiUtil.stripColons('flag_malaysia', (error) {
          expect(error, EmojiMessage.errorMalformedEmojiName);
        }),
        'flag_malaysia');
    expect(
        EmojiUtil.stripColons(':flag_malaysia:', (error) {}), 'flag_malaysia');
    expect(EmojiUtil.stripColons(':flag malaysia:'), ':flag malaysia:');
    expect(EmojiUtil.stripColons(':grey_question:'), 'grey_question');
    expect(EmojiUtil.stripColons('grey_question:'), 'grey_question:');
    expect(EmojiUtil.stripColons(':e-mail:'), 'e-mail');
  });

  test('EmojiUtil.ensureColons()', () {
    expect(EmojiUtil.ensureColons('flag_malaysia'), ':flag_malaysia:');
    expect(EmojiUtil.ensureColons(':flag_malaysia'), ':flag_malaysia:');
    expect(EmojiUtil.ensureColons('flag_malaysia:'), ':flag_malaysia:');
    expect(EmojiUtil.ensureColons(':flag_malaysia:'), ':flag_malaysia:');
  });

  test('EmojiUtil.stripNSM()', () {
    expect(EmojiUtil.normalizeName(String.fromCharCodes(Runes('\u2764\ufe0f'))),
        String.fromCharCodes(Runes('\u2764')));
    expect(EmojiUtil.normalizeName(String.fromCharCodes(Runes('\u2764'))),
        String.fromCharCodes(Runes('\u2764')));
  });

  test('emoji creation & equality', () {
    var coffee = Emoji('flag_malaysia', '🇲🇾');

    expect(emojiFlagMalaysia == coffee, true);

    expect(coffee.name == 'flag_malaysia', true);
    expect(coffee.full == ':flag_malaysia:', true);
    expect(coffee.code == '🇲🇾', true);

    expect(emojiFlagMalaysia.toString(),
        'Emoji{name="flag_malaysia", full=":flag_malaysia:", code="🇲🇾"}');

    expect(emojiFlagMalaysia.toString() == coffee.toString(), true);
  });

  test('emoji clone', () {
    var coffee = emojiFlagMalaysia.clone();

    expect(coffee == emojiFlagMalaysia, true);
  });

  test('get', () {
    expect(emojiParser.get('flag_malaysia'), '🇲🇾');
    expect(emojiParser.get(':flag_malaysia:'), '🇲🇾');

    expect(emojiParser.get('does_not_exist'), Emoji.None);
    expect(emojiParser.get(':does_not_exist:'), Emoji.None);
  });

  test('emoji name', () {
    expect(emojiParser.hasName('flag_malaysia'), true);
    expect(emojiParser.getName('flag_malaysia'), '🇲🇾');

    expect(emojiParser.hasName(':flag_malaysia:'), true);
    expect(emojiParser.getName(':flag_malaysia:'), '🇲🇾');

    expect(emojiParser.hasName('flag-us'), true);
    expect(emojiParser.getName('flag-us'), emojiFlagUS);

    expect(emojiParser.hasName('does_not_exist'), false);
    expect(emojiParser.getName(':does_not_exist:'), Emoji.None);
  });

  test('emoji info', () {
    var heart = emojiParser.info('red_heart');

    expect(heart.name, 'red_heart');
    expect(heart.full, ':red_heart:');
    expect(heart.code, '❤️');
  });

  test('emoji code', () {
    expect(emojiParser.hasEmoji('❤️'), true);
    expect(emojiParser.getEmoji('❤️'), emojiHeart);

    expect(emojiParser.hasEmoji('p'), false);
    expect(emojiParser.getEmoji('p'), Emoji.None);
  });

  test('emojify a text', () {
    // expect(emojiParser.emojify('I :heart: :coffee:'), 'I ❤️ ☕');
    //
    // expect(emojiParser.emojify('I :love coffee:'), 'I :love coffee:');
    // expect(emojiParser.emojify('I :love :coffee'), 'I :love :coffee');
    // expect(emojiParser.emojify('I love: :coffee'), 'I love: :coffee');
    // expect(emojiParser.emojify('I love: coffee:'), 'I love: coffee:');
    //
    // expect(emojiParser.emojify('I :+1: with him'), 'I 👍 with him');
    // expect(emojiParser.emojify('I :heart_on_fire: Flutter so much'),
    //     'I ❤️‍🔥 Flutter so much');

    expect(
        emojiParser.emojify('I :thumbs_up: with him', fnFormat: (code) {
          return 'totally ' + code;
        }),
        'I totally 👍 with him');
  });

  test('unemojify a text', () {
    expect(emojiParser.unemojify('I ❤️ car'), 'I :red_heart: car');
    expect(emojiParser.unemojify('I ❤️ ☕'), 'I :red_heart: :hot_beverage:');

    expect(emojiParser.unemojify('I red_heart car'), 'I red_heart car');
    expect(emojiParser.unemojify('I :red_heart: car'), 'I :red_heart: car');

    // NOTE: both :+1: and :thumbsup: represent same emoji 👍
    // When calling unemojify() only the latter one is mapped.
    expect(emojiParser.unemojify('I 👍 with him'), 'I :thumbs_up: with him');

    expect(emojiParser.unemojify('I ❤️‍🔥 Flutter so much'),
        'I :heart_on_fire: Flutter so much');
  });

  test('emoji name includes some special characters', () {
    var emoji;

    // "umbrella_with_rain_drops":"☔"
    emoji = Emoji('umbrella_with_rain_drops', '☔');
    expect(emojiParser.get('umbrella_with_rain_drops'), emoji);

    // "male-scientist":"👨‍🔬"
    emoji = Emoji('man_scientist', '👨‍🔬');
    expect(emojiParser.get('man_scientist'), emoji);

    // "+1":"👍"
    emoji = Emoji('thumbs_up', '👍');
    expect(emojiParser.get('thumbs_up'), emoji);
  });

  test('count emojis', () {
    expect(emojiParser.count(''), 0);
    expect(emojiParser.count('I love'), 0);
    expect(emojiParser.count('I ❤️ ☕'), 2);
    expect(emojiParser.count('I ❤️‍🔥 Flutter so much'), 1);
  });

  test('count emoji frequency', () {
    expect(emojiParser.frequency('', '❤️'), 0);
    expect(emojiParser.frequency('I love', '❤️'), 0);
    expect(emojiParser.frequency('I ❤️ ☕', '❤️'), 1);
    expect(
        emojiParser.frequency(
            'I ❤️ ☕, they also ❤️ as much as I ❤️ coffee', '❤️'),
        3);
    expect(emojiParser.frequency('I ❤️‍🔥 Flutter so much', '❤️'), 0);
    expect(emojiParser.frequency('I ❤️‍🔥 Flutter so much', '❤️‍🔥'), 1);
  });

  test('replace emoji', () {
    expect(emojiParser.replace('', '❤️', '❤️‍🔥'), null);
    expect(emojiParser.replace('I ❤️ coffee', '❤️', '❤️‍🔥'), 'I ❤️‍🔥 coffee');
  });

  test('parse Emojis', () {
    expect(emojiParser.parseEmojis(''), []);
    expect(emojiParser.parseEmojis('I ❤️ Flutter just like ☕'), ['❤️', '☕']);
  });

  test('initServerData', () async {
    var parser = EmojiParser(init: false);
    expect(parser.hasName('flag_malaysia'), false);
    expect(parser.getName('flag_malaysia'), Emoji.None);
    expect(parser.parseEmojis('I ❤️ Flutter just like ☕'), []);

    await parser.initServerData();
    expect(parser.hasName('flag_malaysia'), true);
    expect(parser.getName('flag_malaysia'), emojiFlagMalaysia);
    expect(parser.parseEmojis('I ❤️ Flutter just like ☕'), ['❤️', '☕']);
  });
}
