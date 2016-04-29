package JEDictionary;

use strict;
use warnings;

use Data::Dumper;
use DOM::Tiny;
use Moo;
use XML::LibXML::Reader;

has [qw/kana_dict kanji_dict/] => ( default => sub { {} }, is => 'rw' );

# TODO Might not need this
has xml_file => ( is => 'ro' );

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

# Builds dictionary from perl data structures that have been dumped into
# files
sub build_dictionary_from_perl {
    my ( $self, $kana_filename, $kanji_filename ) = @_;

    $self->kana_dict( do $kana_filename );
    $self->kanji_dict( do $kanji_filename );
}

# Dumps contents of kana_dict and kanji_dict to files
sub dump_perl_to_files {
    my ( $self, $kana_filename, $kanji_filename ) = @_;

    $Data::Dumper::Indent = 0;

    open my $fh, '>', $kana_filename or die $!;
    print $fh Dumper $self->kana_dict;
    close $fh;

    open $fh, '>', $kanji_filename or die $!;
    print $fh Dumper $self->kanji_dict;
    close $fh;
}

sub get_english_definitions {
    my ( $self, @jp_words ) = @_;

    my %gloss_hash;

    for my $word (@jp_words) {
        if ( my $kana_href = $self->kanji_dict->{$word} ) {
            # Look in kanji dictionary first.
            # $kana_href is of the form
            # { <kana_reading> => <gloss_index> }
            $gloss_hash{$word}->{kana} = [ keys %$kana_href ];

            # There may be several kana readings for a kanji,
            # but the gloss(es) should be the same for each.
            # So we only need to get the gloss(es) for one kana entry.
            my $kana        = ( keys %$kana_href )[0];
            my $gloss_index = $kana_href->{$kana};

            # Get gloss(es) from kana dictionary
            push @{ $gloss_hash{$word}->{glosses} },
                @{ $self->kana_dict->{$kana} }[$gloss_index];
        }
        elsif ( my $glosses = $self->kana_dict->{$word} ) {
            # Word not found in kanji dictionary;
            # is written in kana alone.
            # So just get all glosses for that kana entry.
            $gloss_hash{$word}->{glosses} = $glosses;
        }
        else {
            # The word cannot be found
            $gloss_hash{$word} = {};
        }
    }

    return %gloss_hash;
}

# Pretty-prints list of Japanese words with English glosses to a file.
# See get_english_definitions above for more detail on contents of
# %gloss_hash.
#
# Each line is of the form:
# <kanji>    <kana>[, <kana>...]    <English>[,<English>...]
# or
# <kana>    <English>[,<English>...]
# or
# <kanji/kana>    NO ENTRY FOUND
sub pretty_print_to_file {
    my ( $self, $filename, %gloss_hash ) = @_;

    open my $fh, '>', $filename or die $!;

    for my $key ( keys %gloss_hash ) {
        print $fh $key . '    ';

        # Kanji will have kana entry as well as English gloss(es)
        if ( exists $gloss_hash{$key}->{kana} ) {
            print $fh ( join ', ', @{ $gloss_hash{$key}->{kana} } ) . '    ';
        }

        if ( exists $gloss_hash{$key}->{glosses} ) {
            my @glosses = map @$_, @{ $gloss_hash{$key}->{glosses} };

            print $fh ( join ', ', @glosses ) . '    ';
        }
        else {
            print $fh, 'NO ENTRY FOUND';
        }

        print $fh, "\n";
    }

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
