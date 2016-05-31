package JEDictionary;

use strict;
use warnings;

use Data::Dumper;
use DOM::Tiny;
use Moo;
use Text::CSV;
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
        # Look in kanji dictionary first.
        # $kana_href is of the form
        # { <kana_reading> => <gloss_index>, ... }
        if ( my $kana_href = $self->kanji_dict->{$word} ) {
            # There may be several kana readings for a kanji, which
            # may or may not share the same glosses.
            # Just get the glosses for each one, though there may be
            # repetition.
            for my $kana ( keys %$kana_href ) {
                my $gloss_index = $kana_href->{$kana};

                # Find gloss(es) in kana dictionary
                $gloss_hash{$word}->{$kana}
                    = $self->kana_dict->{$kana}->[$gloss_index];
            }
        }
        elsif ( my $glosses = $self->kana_dict->{$word} ) {
            # Word not found in kanji dictionary;
            # is written in kana alone.
            # So just get all glosses for that kana entry.
            $gloss_hash{$word} = $glosses;
        }
        else {
            # The word cannot be found
            $gloss_hash{$word} = undef;
        }
    }

    # Gloss hash will be of form
    # {
    #   <kanji> => {
    #       <kana_1> => [<glosses>], ...,
    #   },
    #   ...,
    #   <kana> => [
    #       [<glosses_1], ...,
    #   ],
    #   ...,
    #   <word that cannot be found> => {},
    #   ...,
    # }

    return %gloss_hash;
}

# Prints list of Japanese words with English glosses to a .csv file.
# See get_english_definitions above for more detail on contents of
# %gloss_hash.
#
# Each entry is of one of the following forms:
# <kanji>    <kana>    <English> [may be multiple entries for a single kanji]
# or
# <kana>    <English>[,<English>...]
# or
# <kanji/kana>    NO ENTRY FOUND
sub print_to_csv {
    my ( $self, $filename, %gloss_hash ) = @_;

    my $csv = Text::CSV->new(
        { binary => 1, eol => "\012", quote_char => '', sep_char => "\t" } );

    open my $fh, '>', $filename or die $!;

    my @ordered_keys = sort keys %gloss_hash;
    for my $key (@ordered_keys) {
        if ( ref $gloss_hash{$key} eq 'HASH' ) {
            # Kanji entry is hashref:
            #   <kanji> => {
            #       <kana_1> => [<glosses>], ...,
            #   }
            my %kana_hash = %{ $gloss_hash{$key} };

            for my $kana ( keys %kana_hash ) {
                $csv->print( $fh,
                    [ $key, $kana, ( join "\t", @{ $kana_hash{$kana} } ) ] );
            }
        }
        elsif ( ref $gloss_hash{$key} eq 'ARRAY' ) {
            # Kana entry is arrayref of arrayrefs:
            #   <kana> => [
            #       [<glosses_1], ...,
            #   ],
            my @glosses = map @$_, @{ $gloss_hash{$key} };
            $csv->print( $fh, [ $key, ( join "\t", @glosses ) ] );
        }
        else {
            $csv->print( $fh, [ $key, 'NO_ENTRY_FOUND' ] );
        }
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
