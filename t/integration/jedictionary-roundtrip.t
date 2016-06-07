use lib '/home/vmihell-hale/nephila_nacrea/lib';

use strict;
use utf8;
use warnings;

use JEDictionary;

# binmode DATA, ":utf8";

# Roundtrip test
my $jed = JEDictionary->new;

$jed->build_dictionary_from_xml(
    '/home/vmihell-hale/nephila_nacrea/t/data/test-dict.xml');

$jed->dump_perl_to_files(
    '/home/vmihell-hale/nephila_nacrea/t/data/kana-dict',
    '/home/vmihell-hale/nephila_nacrea/t/data/kanji-dict',
);

$jed->build_dictionary_from_perl(
    '/home/vmihell-hale/nephila_nacrea/t/data/kana-dict',
    '/home/vmihell-hale/nephila_nacrea/t/data/kanji-dict',
);

my @words
    = qw/鳥打ち じしん 鳥打日 スチューデントアパシー 日/;

my %gloss_hash = $jed->get_english_definitions(@words);
use Data::Dumper;
warn Dumper \%gloss_hash;
$jed->print_to_csv( '/home/vmihell-hale/nephila_nacrea/t/data/test-csv',
    %gloss_hash );
