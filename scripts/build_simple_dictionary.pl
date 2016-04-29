use lib '/home/vmihell-hale/nephila_nacrea/lib';
use strict;
use warnings;
use utf8;

use JEDictionary;

binmode DATA, ":utf8";

# Original dictionary file from http://www.edrdg.org/jmdict/edict_doc.html
# (JMdict_e.gz)
my $jed = JEDictionary->new(
    xml_file => '/home/vmihell-hale/dictionaries/JMdict_e' );

$jed->build_dictionary_from_xml;

$jed->dump_perl_to_files(
    '/home/vmihell-hale/nephila_nacrea/data/kana-dict',
    '/home/vmihell-hale/nephila_nacrea/data/kanji-dict',
);
