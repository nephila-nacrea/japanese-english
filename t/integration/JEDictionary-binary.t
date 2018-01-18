use lib '../japanese-english/lib';

use strict;
use utf8;
use warnings;

use JEDictionary;
use JETranslator;
use Test2::V0;

# Test build_dictionary_from_binary.
# Test by calling method directly on an empty dictionary object, and then by
# constructing a dictionary object which is populated by binary files in its
# BUILD method.
my $kana_filename  = '../japanese-english/t/data/kana-dict-binary';
my $kanji_filename = '../japanese-english/t/data/kanji-dict-binary';

my $jed_1 = JEDictionary->new(
    xml_filename => '../japanese-english/t/data/test-dict.xml' );

$jed_1->write_dict_hashrefs_to_binary_files( $kana_filename,
    $kanji_filename );
$jed_1->build_dictionary_from_binary( $kana_filename, $kanji_filename );

my $jed_2 = JEDictionary->new(
    kana_filename  => $kana_filename,
    kanji_filename => $kanji_filename,
);

for ( $jed_1, $jed_2 ) {
    is $_->kana_dict,
        {
        'か' => {
            entry_1 => {
                sense_1 => [ ['n-suf'], ['day of month'] ],
                sense_2 => [ ['ctr'],   ['counter for days'] ],
            },
        },
        'じしん' => {
            entry_1 => {
                sense_1 => [
                    [qw/n vs/],
                    [ 'self-confidence', 'confidence (in oneself)' ],
                ],
            },
            entry_2 => { sense_1 => [ ['n'], ['earthquake'] ] },
        },
        'じぶるい' =>
            { entry_1 => { sense_1 => [ ['n'], ['earthquake'] ] } },
        'とりうち' => {
            entry_1 =>
                { sense_1 => [ ['n'], [ 'fowling', 'shooting birds' ] ] },
        },
        'ない' => { entry_1 => { sense_1 => [ ['n'], ['earthquake'] ] } },
        'なえ' => { entry_1 => { sense_1 => [ ['n'], ['earthquake'] ] } },
        'にち' => {
            entry_1 => {
                sense_1 => [ ['n'],                ['Sunday'] ],
                sense_2 => [ ['suf'],              ['day (of the month)'] ],
                sense_3 => [ [qw/suf ctr/],        ['counter for days'] ],
                sense_4 => [ [qw/n n-suf n-pref/], ['Japan'] ],
            },
        },
        'ひ' => {
            entry_1 => {
                sense_1 => [ [qw/n-adv n-t/], [ 'day', 'days' ] ],
                sense_2 =>
                    [ [qw/n-adv n-t/], [ 'sun', 'sunshine', 'sunlight' ] ],
                sense_3 => [
                    [qw/n-adv n-t/], [ 'case (esp. unfortunate)', 'event' ],
                ],
            },
        },
        'スチューデントアパシー' =>
            { entry_1 => { sense_1 => [ ['n'], ['student apathy'] ] } },
        'スチューデント・アパシー' =>
            { entry_1 => { sense_1 => [ ['n'], ['student apathy'] ] } },
        'とり' => {
            entry_1 => {
                sense_1 => [ ['n'], ['bird'] ],
                sense_2 => [
                    ['n'],
                    [ 'bird meat (esp. chicken meat)', 'fowl', 'poultry' ],
                ],
            },
        },
        },
        'build_dictionary_from_binary: kana_dict correct';

    is $_->kanji_dict,
        {
        '鳥'    => { 'とり' => 'entry_1', },
        '禽'    => { 'とり' => 'entry_1', },
        '地震' => {
            'じしん'    => 'entry_2',
            'ない'       => 'entry_1',
            'なえ'       => 'entry_1',
            'じぶるい' => 'entry_1',
        },
        '日' =>
            { 'か' => 'entry_1', 'ひ' => 'entry_1', 'にち' => 'entry_1' },
        '自信'    => { 'じしん'    => 'entry_1' },
        '陽'       => { 'ひ'          => 'entry_1' },
        '鳥打ち' => { 'とりうち' => 'entry_1' },
        '鳥撃ち' => { 'とりうち' => 'entry_1' },
        },
        'build_dictionary_from_binary: kanji_dict correct';
}

# Test get_english_definitions

my $jet = JETranslator->new( dictionary => $jed_2 );

is { $jet->get_english_definitions('鳥打ち') },
    { '鳥打ち' =>
        { 'とりうち' => _bag( 'fowling', 'shooting birds' ) }, },
    'binary get_english_definitions: kanji word';

is { $jet->get_english_definitions('とりうち') },
    { 'とりうち' => _bag( 'fowling', 'shooting birds' ) },
    'binary get_english_definitions: kana word';

is { $jet->get_english_definitions('じしん') },
    { 'じしん' =>
        _bag( 'self-confidence', 'confidence (in oneself)', 'earthquake' ), },
    'binary get_english_definitions: kana word with multiple gloss-groups';

is { $jet->get_english_definitions('日') },
    {
    '日' => {
        'か'    => _bag( 'day of month', 'counter for days' ),
        'にち' => _bag(
            'Sunday',
            'day (of the month)',
            'counter for days', 'Japan'
        ),
        'ひ' => _bag(
            'day', 'days', 'sun', 'sunshine', 'sunlight',
            'case (esp. unfortunate)', 'event',
        ),
    },
    },
    'binary get_english_definitions: kanji word with multiple readings';

is { $jet->get_english_definitions('私の名前はうちじし') },
    {
    'うち' => undef,
    'じし' => undef,
    'の'    => undef,
    'は'    => undef,
    '名前' => undef,
    '私'    => undef,
    },
    'binary get_english_definitions: no matches found';

is {
    $jet->get_english_definitions(
        'わたしのなまえはとりうちじし')
},
    {
    'うち' => undef,
    'じし' => undef,
    'とり' =>
        _bag( 'bird', 'bird meat (esp. chicken meat)', 'fowl', 'poultry' ),
    'なまえ' => undef,
    'の'       => undef,
    'は'       => undef,
    'わたし' => undef,
    },
    'binary get_english_definitions: match found from tokenisation';

is {
    $jet->get_english_definitions(
        'とりうち', '地震', 'じしん',
        'スチューデントアパシー',
        'スチューデント・アパシー'
        )
},
    {
    'とりうち' => _bag( 'fowling', 'shooting birds' ),
    '地震'       => {
        'じしん'    => ['earthquake'],
        'じぶるい' => ['earthquake'],
        'ない'       => ['earthquake'],
        'なえ'       => ['earthquake'],
    },
    'じしん' =>
        _bag( 'self-confidence', 'confidence (in oneself)', 'earthquake' ),
    'スチューデントアパシー'    => ['student apathy'],
    'スチューデント・アパシー' => ['student apathy'],
    },
    'binary get_english_definitions: multiple inputs';

sub _bag {
    my @items = @_;

    return bag {
        item $_ for @items;
        end();
    };
}

done_testing;
