use lib '../japanese-english/lib';

use strict;
use utf8;
use warnings;

use JEDictionary;
use Test2::V0;

# Test build_dictionary_from_xml.
# Test by calling method directly on an empty dictionary object, and then by
# constructing a dictionary object which is populated by XML file in its
# BUILD method.
my $xml_filename = '../japanese-english/t/data/test-dict.xml';

my $jed_1 = JEDictionary->new( no_dictionary_build => 1 );
$jed_1->build_dictionary_from_xml($xml_filename);

my $jed_2 = JEDictionary->new( xml_filename => $xml_filename );

for ( $jed_1, $jed_2 ) {
    is $_->kana_dict,
        {
        'か' => [ [ 'day of month', 'counter for days' ] ],
        'じしん' => [
            [ 'self-confidence', 'confidence (in oneself)' ],
            ['earthquake'],
        ],
        'じぶるい' => [ ['earthquake'] ],
        'とりうち' => [ [ 'fowling', 'shooting birds' ] ],
        'ない'       => [ ['earthquake'] ],
        'なえ'       => [ ['earthquake'] ],
        'にち' => [
            [ 'Sunday', 'day (of the month)', 'counter for days', 'Japan' ]
        ],
        'ひ' => [
            [   'day', 'days', 'sun', 'sunshine', 'sunlight',
                'case (esp. unfortunate)', 'event',
            ]
        ],
        'スチューデントアパシー'    => [ ['student apathy'] ],
        'スチューデント・アパシー' => [ ['student apathy'] ],
        'とり'                               => [
            [ 'bird', 'bird meat (esp. chicken meat)', 'fowl', 'poultry' ]
        ],
        },
        'build_dictionary_from_xml: kana_dict correct';

    is $_->kanji_dict,
        {
        '鳥'    => { 'とり' => 0, },
        '禽'    => { 'とり' => 0, },
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
}

# Test get_english_definitions

is { $jed_2->get_english_definitions('鳥打ち') },
    { '鳥打ち' => { 'とりうち' => [ 'fowling', 'shooting birds' ] }, },
    'xml get_english_definitions: kanji word';

is { $jed_2->get_english_definitions('とりうち') },
    { 'とりうち' => [ [ 'fowling', 'shooting birds' ] ] },
    'xml get_english_definitions: kana word';

is { $jed_2->get_english_definitions('じしん') },
    { 'じしん' =>
        [ [ 'self-confidence', 'confidence (in oneself)' ], ['earthquake'] ],
    },
    'xml get_english_definitions: kana word with multiple gloss-groups';

is { $jed_2->get_english_definitions('日') },
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
    'xml get_english_definitions: kanji word with multiple readings';

is { $jed_2->get_english_definitions('うちじしん') },
    {
    'うち' => undef,
    'じし' => undef,
    'ん'    => undef,
    },
    'xml get_english_definitions: no matches found';

is { $jed_2->get_english_definitions('とりうちじしん') },
    {
    'とり' =>
        [ [ 'bird', 'bird meat (esp. chicken meat)', 'fowl', 'poultry' ] ],
    'うち' => undef,
    'じし' => undef,
    'ん'    => undef,
    },
    'xml get_english_definitions: match found from tokenisation';

is {
    $jed_2->get_english_definitions(
        'とりうち', '地震', 'じしん',
        'スチューデントアパシー',
        'スチューデント・アパシー'
        )
},
    {
    'とりうち' => [ [ 'fowling', 'shooting birds' ] ],
    '地震' => {
        'じしん'    => ['earthquake'],
        'じぶるい' => ['earthquake'],
        'ない'       => ['earthquake'],
        'なえ'       => ['earthquake'],
    },
    'じしん' =>
        [ [ 'self-confidence', 'confidence (in oneself)' ], ['earthquake'] ],
    'スチューデントアパシー'    => [ ['student apathy'] ],
    'スチューデント・アパシー' => [ ['student apathy'] ],
    },
    'xml get_english_definitions: multiple inputs';

done_testing;
