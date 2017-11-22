use lib '../japanese-english/lib';

use strict;
use utf8;
use warnings;

use JEDictionary;
use JETranslator;

# Roundtrip 'test'.
# Not (currently) a test file in the strictest sense, as there are no tests
# for 'prove' to run, but is still useful for checking overall behaviour of
# JEDictionary.pm & JETranslator.pm.
my $jed = JEDictionary->new( no_dictionary_build => 1 );

$jed->build_dictionary_from_xml('../japanese-english/t/data/test-dict.xml');

$jed->write_dict_hashrefs_to_binary_files(
    '../japanese-english/t/data/kana-dict',
    '../japanese-english/t/data/kanji-dict',
);

$jed->build_dictionary_from_binary(
    '../japanese-english/t/data/kana-dict',
    '../japanese-english/t/data/kanji-dict',
);

my $jet = JETranslator->new( dictionary => $jed );

my @words = (
    '鳥打ち', 'じしん',
    '鳥打日', 'スチューデントアパシー',
    '日'
);

my %gloss_hash = $jet->get_english_definitions(@words);

$jet->print_to_csv( '../japanese-english/t/data/test-csv', %gloss_hash );
