use lib '../japanese-english/lib';

use strict;
use utf8;
use warnings;

use JEDictionary;

# Roundtrip test
my $jed = JEDictionary->new;

$jed->build_dictionary_from_xml('../japanese-english/t/data/test-dict.xml');

$jed->write_dict_hashrefs_to_binary_files(
    '../japanese-english/t/data/kana-dict',
    '../japanese-english/t/data/kanji-dict',
);

$jed->build_dictionary_from_binary(
    '../japanese-english/t/data/kana-dict',
    '../japanese-english/t/data/kanji-dict',
);

my @words = (
    '鳥打ち', 'じしん',
    '鳥打日', 'スチューデントアパシー',
    '日'
);

my %gloss_hash = $jed->get_english_definitions(@words);

$jed->print_to_csv( '../japanese-english/t/data/test-csv', %gloss_hash );
