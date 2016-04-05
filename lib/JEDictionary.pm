package JEDictionary;

use strict;
use warnings;

use DOM::Tiny;
use Moo;
use XML::LibXML::Reader;

has [qw/kana_dict kanji_dict/] => ( default => sub { {} }, is => 'rw' );

has xml_file => ( is => 'ro', required => 1 );

sub build_dictionary_from_xml {
    my $self = shift;

    my $reader = XML::LibXML::Reader->new(
        encoding => 'utf8',
        location => $self->xml_file,
    ) or die $!;

    while ( $reader->read ) {
        $reader->nextElement('entry');
        $self->_add_to_dictionary( $reader->readInnerXml );
    }
}

# Dumps contents of kana_dict and kanji_dict to files
sub dump_perl_to_files {
    my ( $self, $kana_filename, $kanji_filename ) = @_;
    use Data::Dumper;
    $Data::Dumper::Indent = 0;
    open my $fh, '>', $kana_filename or die $!;

    print $fh Dumper $self->kana_dict;

    close $fh;

    open $fh, '>', $kanji_filename or die $!;

    print $fh Dumper $self->kanji_dict;

    close $fh;
}

sub _add_to_dictionary {
    my ( $self, $xml ) = @_;

    my $dom = DOM::Tiny->new($xml);

    # An entry should always have at least one kana reading ('reb'
    # element) and one English definition ('gloss' element), so skip
    # if either one is absent.
    # 'keb' = kanji reading
    my $kana_elems;
    return unless $kana_elems = $dom->find('reb');

    my @gloss_texts;
    return unless @gloss_texts = map $_->text, @{ $dom->find('gloss') };

    my $kanji_elems = $dom->find('keb');

    for my $kana (@$kana_elems) {
        # Add to the kana_dict hashref.
        # Each value is an arrayref of arrayrefs,
        # that each contain the glosses for a particular kanji reading
        # (as a kana reading may map to multiple kanji readings,
        # e.g. 地震 and 自信 both map to じしん).
        # The index of each new arrayref is used in the kanji dictionary
        # below.
        push @{ $self->kana_dict->{ $kana->text } }, \@gloss_texts;

        my $gloss_index = @{ $self->kana_dict->{ $kana->text } } - 1;

        for my $kanji (@$kanji_elems) {
            # Add to the kanji_dict hashref.
            # Each value is a hashref mapping a kana reading to its gloss
            # index.
            # So e.g. if you were to look up 地震 in the kanji dictionary,
            # you would get a kana reading of じしん and an index of X;
            # the kana and index can be used to look up the correct English
            # gloss(es) in the kana dictionary (e.g. 'earthquake' as opposed
            # to 'confidence').
            # A kanji entry may have more than one kana reading.
            $self->kanji_dict->{ $kanji->text }->{ $kana->text }
                = $gloss_index;
        }
    }
}

1;
