use lib '../nephila_nacrea/lib';

use strict;
use utf8;
use warnings;

use JEDictionary;
use Test::Deep;
use Test::More;

#
# Test build_dictionary_from_xml
#
my $jed = new_dict();

$jed->build_dictionary_from_xml('../nephila_nacrea/t/data/test-dict.xml');

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
# Test get_english_definitions with dictionary built from xml
#
$jed = new_dict();

$jed->build_dictionary_from_xml('../nephila_nacrea/t/data/test-dict.xml');

is_deeply { $jed->get_english_definitions('鳥打ち') },
    { '鳥打ち' => { 'とりうち' => [ 'fowling', 'shooting birds' ] }, },
    'xml get_english_definitions: kanji word';

is_deeply { $jed->get_english_definitions('とりうち') },
    { 'とりうち' => [ [ 'fowling', 'shooting birds' ] ] },
    'xml get_english_definitions: kana word';

is_deeply { $jed->get_english_definitions('じしん') },
    { 'じしん' =>
        [ [ 'self-confidence', 'confidence (in oneself)' ], ['earthquake'] ],
    },
    'xml get_english_definitions: kana word with multiple gloss-groups';

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
    'xml get_english_definitions: kanji word with multiple readings';

use Data::Dumper;
warn Dumper { $jed->get_english_definitions('とりうちじしん') };
is_deeply { $jed->get_english_definitions('とりうちじしん') },
    {
    'とり' => undef,
    'うち' => undef,
    'じし' => undef,
    'ん'    => undef,
    },
    'xml get_english_definitions: no match found';

cmp_deeply {
    $jed->get_english_definitions(
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

#
# Test get_english_definitions with dictionary built from binary
#
$jed = new_dict();

$jed->build_dictionary_from_xml('../nephila_nacrea/t/data/test-dict.xml');

my @binary_dict_files = (
    '../nephila_nacrea/t/unit/data/kana-dict',
    '../nephila_nacrea/t/unit/data/kanji-dict',
);
$jed->write_dict_hashrefs_to_binary_files(@binary_dict_files);
$jed->build_dictionary_from_binary(@binary_dict_files);

is_deeply { $jed->get_english_definitions('鳥打ち') },
    { '鳥打ち' => { 'とりうち' => [ 'fowling', 'shooting birds' ] }, },
    'binary get_english_definitions: kanji word';

is_deeply { $jed->get_english_definitions('とりうち') },
    { 'とりうち' => [ [ 'fowling', 'shooting birds' ] ] },
    'binary get_english_definitions: kana word';

is_deeply { $jed->get_english_definitions('じしん') },
    { 'じしん' =>
        [ [ 'self-confidence', 'confidence (in oneself)' ], ['earthquake'] ],
    },
    'binary get_english_definitions: kana word with multiple gloss-groups';

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
    'binary get_english_definitions: kanji word with multiple readings';

is_deeply { $jed->get_english_definitions('とりうちじしん') },
    {
    'とり'    => undef,
    'うち'    => undef,
    'じしん' => undef,
    },
    'binary get_english_definitions: no match found';

cmp_deeply {
    $jed->get_english_definitions(
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
    'binary get_english_definitions: multiple inputs';

sub new_dict { JEDictionary->new }

done_testing;
