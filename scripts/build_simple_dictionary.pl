use strict;
use warnings;
use utf8;

use DOM::Tiny;
use Time::HiRes 'gettimeofday';
use XML::LibXML::Reader;

binmode STDOUT, ":utf8";

# Original dictionary file from http://www.edrdg.org/jmdict/edict_doc.html
# (JMdict_e.gz)
my $reader = XML::LibXML::Reader->new(
    encoding => 'utf8',
    location => '/home/vmihell-hale/dictionaries/JMdict_e'
) or die $!;

my %kana_dict;
my %kanji_dict;

my $start = gettimeofday;
while ( $reader->read ) {
    $reader->nextElement('entry');

    my $entry_dom = DOM::Tiny->new( $reader->readInnerXml );

    my $kanji_elems = $entry_dom->find('keb');

    my $kana_elems = $entry_dom->find('reb');

    # Arrayref containing only the text of each gloss element
    my $gloss_texts = [ map $_->text, @{ $entry_dom->find('gloss') } ];

    for my $kana (@$kana_elems) {
# Add to the kana dictionary.
# Each entry is an arrayref of arrayrefs, that each contain
# the glosses for a particular kanji reading (as a kana reading may
# map to multiple kanji readings, e.g. 地震 and 自信 both map to じしん).
# The index of each new arrayref is used in the kanji dictionary below.
        push @{ $kana_dict{ $kana->text } }, $gloss_texts;

        my $gloss_index = scalar @{ $kana_dict{ $kana->text } } - 1;

        # Now add to the kanji dictionary
        for my $kanji (@$kanji_elems) {
       # Each entry is a hashref mapping a kana reading to its gloss index.
       # So e.g. if you were to look up 地震 in the kanji dictionary, you
       # would get a kana reading of じしん and an index of X; the kana and
       # index can be used to look up the correct English gloss(es) in the
       # kana dictionary (e.g. 'earthquake' as opposed to 'confidence').
       # A kanji entry may have more than one kana reading.
            $kanji_dict{ $kanji->text }->{ $kana->text } = $gloss_index;
        }
    }
}
my $end = gettimeofday;

print $end - $start;

# for my $kanji ( keys %kanji_dict ) {
#     print "$kanji\n";

#     for my $kana ( keys %{ $kanji_dict{$kanji} } ) {
#         print "\t$kana -> $kanji_dict{$kanji}->{$kana}\n";
#     }
# }

# for my $kana ( keys %kana_dict ) {
#     print "$kana\n";

#     for my $glosses ( $kana_dict{$kana} ) {
#         print "\t@$_\n" for @$glosses;
#     }
# }

get_gloss('地震');
get_gloss('自信');

sub get_gloss {
    my ($japanese_string) = @_;

    my $kana_hashref = $kanji_dict{$japanese_string};

    if ( keys %$kana_hashref ) {
        for my $kana ( keys %$kana_hashref ) {
            print "$kana\n";
            my $index = $kana_hashref->{$kana};
            print "\t$index\n";

            print "\t@{ $kana_dict{$kana}->[$index] }\n";
        }
    }
}
