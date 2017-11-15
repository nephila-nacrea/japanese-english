use lib '../japanese-english/lib';

use strict;
use warnings;
use utf8;

use JEDictionary;

# Original dictionary file from http://www.edrdg.org/jmdict/edict_doc.html
# (JMdict_e.gz)
my $jed = JEDictionary->new(xml_filename => '../dictionaries/JMdict_e');

$jed->write_dict_hashrefs_to_binary_files(
    '../japanese-english/data/kana-dict',
    '../japanese-english/data/kanji-dict',
);
