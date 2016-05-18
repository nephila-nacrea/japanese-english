use lib '/home/vmihell-hale/nephila_nacrea/lib';

use strict;
use utf8;
use warnings;

use JEDictionary;
use Test::Deep;
use Test::More;

#
# Test _add_to_dictionary
#

my $jed = new_dict();

$jed->_add_to_dictionary(
    '<entry>
    </entry>'
);

is_deeply $jed->kana_dict,  {}, 'Add empty entry to kana_dict';
is_deeply $jed->kanji_dict, {}, 'Add empty entry to kanji_dict';

$jed = new_dict();

# No keb
$jed->_add_to_dictionary(
    '<entry>
    <ent_seq>1468820</ent_seq>
    <r_ele>
    <reb>としとる</reb>
    </r_ele>
    <sense>
    <pos>&v5r;</pos>
    <pos>&vi;</pos>
    <gloss>to grow old</gloss>
    </sense>
    </entry>'
);

is_deeply $jed->kana_dict, { 'としとる' => [ ['to grow old'] ] },
    'Add entry with no kanji: kana_dict';
is_deeply $jed->kanji_dict, {}, 'Add entry with no kanji: kanji_dict';

$jed = new_dict();

# No reb
$jed->_add_to_dictionary(
    '<entry>
    <ent_seq>1468820</ent_seq>
    <k_ele>
    <keb>年取る</keb>
    </k_ele>
    <sense>
    <pos>&v5r;</pos>
    <pos>&vi;</pos>
    <gloss>to grow old</gloss>
    </sense>
    </entry>'
);

is_deeply $jed->kana_dict,  {}, 'Add entry with no kana: kana_dict';
is_deeply $jed->kanji_dict, {}, 'Add entry with no kana: kanji_dict';

$jed = new_dict();

# No gloss
$jed->_add_to_dictionary(
    '<entry>
    <ent_seq>1468820</ent_seq>
    <k_ele>
    <keb>年取る</keb>
    </k_ele>
    <r_ele>
    <reb>としとる</reb>
    </r_ele>
    <sense>
    <pos>&v5r;</pos>
    <pos>&vi;</pos>
    </sense>
    </entry>'
);

is_deeply $jed->kana_dict,  {}, 'Add entry with no gloss: kana_dict';
is_deeply $jed->kanji_dict, {}, 'Add entry with no gloss: kanji_dict';

$jed = new_dict();

# One of each
$jed->_add_to_dictionary(
    '<entry>
    <ent_seq>1468820</ent_seq>
    <k_ele>
    <keb>年取る</keb>
    </k_ele>
    <r_ele>
    <reb>としとる</reb>
    </r_ele>
    <sense>
    <pos>&v5r;</pos>
    <pos>&vi;</pos>
    <gloss>to grow old</gloss>
    </sense>
    </entry>'
);

is_deeply $jed->kana_dict, { 'としとる' => [ ['to grow old'] ] },
    'Add entry with one of each element: kana_dict';
is_deeply $jed->kanji_dict, { '年取る' => { 'としとる' => 0 } },
    'Add entry with one of each element: kanji_dict';

$jed = new_dict();

# Two of each
$jed->_add_to_dictionary(
    '<entry>
    <ent_seq>1468820</ent_seq>
    <k_ele>
    <keb>年取る</keb>
    </k_ele>
    <k_ele>
    <keb>歳取る</keb>
    </k_ele>
    <r_ele>
    <reb>としとる</reb>
    </r_ele>
    <r_ele>
    <reb>トシトル</reb>
    </r_ele>
    <sense>
    <pos>&v5r;</pos>
    <pos>&vi;</pos>
    <gloss>to grow old</gloss>
    <gloss>to age</gloss>
    </sense>
    </entry>'
);

is_deeply $jed->kana_dict,
    {
    'としとる' => [ [ 'to grow old', 'to age' ] ],
    'トシトル' => [ [ 'to grow old', 'to age' ] ],
    },
    'Add entry with two of each element: kana_dict';
is_deeply $jed->kanji_dict,
    {
    '年取る' => { 'としとる' => 0, 'トシトル' => 0, },
    '歳取る' => { 'としとる' => 0, 'トシトル' => 0, },
    },
    'Add entry with two of each element: kanji_dict';

$jed = new_dict();

# Different kanji with same kana reading
$jed->_add_to_dictionary(
    '<entry>
    <ent_seq>1468820</ent_seq>
    <k_ele>
    <keb>自信</keb>
    </k_ele>
    <r_ele>
    <reb>じしん</reb>
    </r_ele>
    <sense>
    <gloss>confidence</gloss>
    </sense>
    </entry>'
);
$jed->_add_to_dictionary(
    '<entry>
    <ent_seq>1468820</ent_seq>
    <k_ele>
    <keb>地震</keb>
    </k_ele>
    <r_ele>
    <reb>じしん</reb>
    </r_ele>
    <sense>
    <gloss>earthquake</gloss>
    </sense>
    </entry>'
);

is_deeply $jed->kana_dict,
    { 'じしん' => [ ['confidence'], ['earthquake'] ] },
    'Kanji with same kana reading: kana_dict';
is_deeply $jed->kanji_dict,
    {
    '自信' => { 'じしん' => 0 },
    '地震' => { 'じしん' => 1 },
    },
    'Kanji with same kana reading: kanji_dict';

# Identical kanji, different entries
$jed = new_dict();

$jed->_add_to_dictionary(
    '<entry>
    <ent_seq>1463770</ent_seq>
    <k_ele>
    <keb>日</keb>
    </k_ele>
    <k_ele>
    <keb>陽</keb>
    </k_ele>
    <r_ele>
    <reb>ひ</reb>
    </r_ele>
    <sense>
    <gloss>day</gloss>
    <gloss>days</gloss>
    </sense>
    <sense>
    <gloss>sun</gloss>
    <gloss>sunshine</gloss>
    <gloss>sunlight</gloss>
    </sense>
    <sense>
    <gloss>case (esp. unfortunate)</gloss>
    <gloss>event</gloss>
    </sense>
    </entry>'
);
$jed->_add_to_dictionary(
    '<entry>
    <ent_seq>2083100</ent_seq>
    <k_ele>
    <keb>日</keb>
    </k_ele>
    <r_ele>
    <reb>にち</reb>
    </r_ele>
    <sense>
    <gloss>Sunday</gloss>
    </sense>
    <sense>
    <gloss>day (of the month)</gloss>
    </sense>
    <sense>
    <gloss>counter for days</gloss>
    </sense>
    <sense>
    <gloss>Japan</gloss>
    </sense>
    </entry>'
);
$jed->_add_to_dictionary(
    '<entry>
    <ent_seq>2083110</ent_seq>
    <k_ele>
    <keb>日</keb>
    </k_ele>
    <r_ele>
    <reb>か</reb>
    </r_ele>
    <sense>
    <gloss>day of month</gloss>
    </sense>
    <sense>
    <gloss>counter for days</gloss>
    </sense>
    </entry>'
);

cmp_deeply $jed->kana_dict,
    {
    'か' => [ [ 'day of month', 'counter for days' ] ],
    'にち' =>
        [ [ 'Sunday', 'day (of the month)', 'counter for days', 'Japan' ] ],
    'ひ' => [
        [   'day', 'days', 'sun', 'sunshine', 'sunlight',
            'case (esp. unfortunate)', 'event',
        ]
    ],
    },
    'Identical kanji with different readings: kana_dict';
is_deeply $jed->kanji_dict,
    {
    '日' => {
        'か'    => 0,
        'ひ'    => 0,
        'にち' => 0,
    },
    '陽' => { 'ひ' => 0 },
    },
    'Identical kanji with different readings: kanji_dict';

#
# Test build_dictionary_from_xml
#
$jed = new_dict( xml_file =>
        '/home/vmihell-hale/nephila_nacrea/t/unit/data/test-dict.xml' );

$jed->build_dictionary_from_xml;

is_deeply $jed->kana_dict,
    {
    'か' => [ [ 'day of month', 'counter for days' ] ],
    'じしん' =>
        [ [ 'self-confidence', 'confidence (in oneself)' ], ['earthquake'], ],
    'じぶるい' => [ ['earthquake'] ],
    'とりうち' => [ [ 'fowling', 'shooting birds' ] ],
    'ない'       => [ ['earthquake'] ],
    'なえ'       => [ ['earthquake'] ],
    'にち' =>
        [ [ 'Sunday', 'day (of the month)', 'counter for days', 'Japan' ] ],
    'ひ' => [
        [   'day', 'days', 'sun', 'sunshine', 'sunlight',
            'case (esp. unfortunate)', 'event',
        ]
    ],
    'スチューデントアパシー'    => [ ['student apathy'] ],
    'スチューデント・アパシー' => [ ['student apathy'] ],
    },
    'build_dictionary_from_xml: kana_dict correct';

is_deeply $jed->kanji_dict,
    {
    '地震' => {
        'じしん'    => 1,
        'ない'       => 0,
        'なえ'       => 0,
        'じぶるい' => 0,
    },
    '日'       => { 'か'          => 0, 'ひ' => 0, 'にち' => 0 },
    '自信'    => { 'じしん'    => 0 },
    '陽'       => { 'ひ'          => 0 },
    '鳥打ち' => { 'とりうち' => 0 },
    '鳥撃ち' => { 'とりうち' => 0 },
    },
    'build_dictionary_from_xml: kanji_dict correct';

#
# Test get_english_definitions
#
$jed = new_dict( xml_file =>
        '/home/vmihell-hale/nephila_nacrea/t/unit/data/test-dict.xml' );

$jed->build_dictionary_from_xml;

is_deeply { $jed->get_english_definitions('鳥打ち') },
    { '鳥打ち' => { 'とりうち' => [ 'fowling', 'shooting birds' ] }, },
    'get_english_definitions: kanji word';

is_deeply { $jed->get_english_definitions('とりうち') },
    { 'とりうち' => [ [ 'fowling', 'shooting birds' ] ] },
    'get_english_definitions: kana word';

is_deeply { $jed->get_english_definitions('じしん') },
    { 'じしん' =>
        [ [ 'self-confidence', 'confidence (in oneself)' ], ['earthquake'] ],
    },
    'get_english_definitions: kana word with multiple gloss-groups';

is_deeply { $jed->get_english_definitions('日') },
    {
    '日' => {
        'か' => [ 'day of month', 'counter for days' ],
        'にち' =>
            [ 'Sunday', 'day (of the month)', 'counter for days', 'Japan' ],
        'ひ' => [
            'day', 'days', 'sun', 'sunshine', 'sunlight',
            'case (esp. unfortunate)', 'event',
        ],
    },
    },
    'get_english_definitions: kanji word with multiple readings';

is_deeply { $jed->get_english_definitions('とりうちじしん') },
    { 'とりうちじしん' => undef },
    'get_english_definitions: no match found';

cmp_deeply {
    $jed->get_english_definitions( 'とりうち', '地震',
        'スチューデントアパシー' )
},
    {
    'とりうち' => [ [ 'fowling', 'shooting birds' ] ],
    '地震' => {
        'じしん'    => ['earthquake'],
        'じぶるい' => ['earthquake'],
        'ない'       => ['earthquake'],
        'なえ'       => ['earthquake'],
    },
    'スチューデントアパシー' => [ ['student apathy'] ],
    },
    'get_english_definitions: multiple inputs';

sub new_dict {
    return JEDictionary->new(@_);
}

done_testing;
