use lib '../nephila_nacrea/lib';

use strict;
use warnings;
use utf8;

use JEDictionary;

# Original dictionary file from http://www.edrdg.org/jmdict/edict_doc.html
# (JMdict_e.gz)
my $jed = JEDictionary->new;

$jed->build_dictionary_from_xml('../dictionaries/JMdict_e');

$jed->dump_perl_to_files(
    '../nephila_nacrea/data/kana-dict',
    '../nephila_nacrea/data/kanji-dict',
);
