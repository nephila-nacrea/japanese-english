use lib '../nephila_nacrea/lib';

use strict;
use utf8;
use warnings;

use JEDictionary;

# Roundtrip test
my $jed = JEDictionary->new;

$jed->build_dictionary_from_xml('../nephila_nacrea/t/data/test-dict.xml');

$jed->dump_perl_to_files(
    '../nephila_nacrea/t/data/kana-dict',
    '../nephila_nacrea/t/data/kanji-dict',
);

$jed->build_dictionary_from_perl(
    '../nephila_nacrea/t/data/kana-dict',
    '../nephila_nacrea/t/data/kanji-dict',
);

my @words
    = qw/鳥打ち じしん 鳥打日 スチューデントアパシー 日/;

my %gloss_hash = $jed->get_english_definitions(@words);
use Data::Dumper;
warn Dumper \%gloss_hash;
$jed->print_to_csv( '../nephila_nacrea/t/data/test-csv', %gloss_hash );
