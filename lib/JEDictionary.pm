package JEDictionary;

use strict;
use warnings;

use File::Slurper 'read_binary';
use Mojo::DOM58;
use Moo;
# FIXME Use OO interface for Sereal (see https://metacpan.org/pod/Sereal)
use Sereal qw/decode_sereal encode_sereal/;
use Text::CSV;
use Text::MeCab;
use Unicode::UTF8 'decode_utf8';
use XML::LibXML::Reader;

use constant {
    DEFAULT_KANA_FILENAME  => '../japanese-english/data/kana-dict',
    DEFAULT_KANJI_FILENAME => '../japanese-english/data/kanji-dict',
};

has kana_dict  => ( default => sub { {} }, is => 'rw' );
has kanji_dict => ( default => sub { {} }, is => 'rw' );

sub BUILD {
    my ( $self, $args ) = @_;

    # no_dictionary_build is used for testing purposes, to force an empty
    # dictionary
    return if $args->{no_dictionary_build};

    return $self->build_dictionary_from_xml( $args->{xml_filename} )
        if $args->{xml_filename};

    $self->build_dictionary_from_binary(
        $args->{kana_filename}  || DEFAULT_KANA_FILENAME,
        $args->{kanji_filename} || DEFAULT_KANJI_FILENAME
    );
}

# Builds dictionary from binary that has been dumped into files
sub build_dictionary_from_binary {
    my ( $self, $kana_filename, $kanji_filename ) = @_;

    $self->kana_dict( decode_sereal( read_binary $kana_filename ) );
    $self->kanji_dict( decode_sereal( read_binary $kanji_filename ) );
}

sub build_dictionary_from_xml {
    my ( $self, $file ) = @_;

    my $reader = XML::LibXML::Reader->new(
        encoding => 'utf8',
        location => $file,
    ) or die $!;

    while ( $reader->read ) {
        $reader->nextElement('entry');
        $self->_add_to_dictionary( $reader->readInnerXml );
    }
}

# Converts kana_dict and kanji_dict hashrefs to binary & writes to files
sub write_dict_hashrefs_to_binary_files {
    my ( $self, $kana_filename, $kanji_filename ) = @_;

    open my $fh, '>:raw', $kana_filename or die $!;
    print $fh encode_sereal( $self->kana_dict );
    close $fh or die $!;

    open $fh, '>:raw', $kanji_filename or die $!;
    print $fh encode_sereal( $self->kanji_dict );
    close $fh or die $!;
}

sub get_english_definitions {
    my ( $self, @jp_words ) = @_;

    my %gloss_hash;

    for my $word (@jp_words) {
        $self->_add_definition_for_word( \%gloss_hash, $word );
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

            # FIXME Why are there undefs instead of arrayrefs?
            my @glosses = map @{ $_ // [] }, @{ $gloss_hash{$key} };
            $csv->print( $fh, [ $key, ( join "\t", @glosses ) ] );
        }
        else {
            $csv->print( $fh, [ $key, 'NO_ENTRY_FOUND' ] );
        }
    }

    close $fh;
}

sub _add_definition_for_word {
    my ( $self, $gloss_hashref, $word ) = @_;

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
            $gloss_hashref->{$word}{$kana}
                = $self->kana_dict->{$kana}->[$gloss_index];
        }
    }
    elsif ( my $glosses = $self->kana_dict->{$word} ) {
        # Word not found in kanji dictionary;
        # is written in kana alone.
        # So just get all glosses for that kana entry.
        $gloss_hashref->{$word} = $glosses;
    }
    else {
        # Word cannot be found - perhaps it is a phrase that can be
        # tokenised.
        my @tokens = _tokenise($word);

        # No point checking further if there is only one token, as will only
        # have same result (or lack thereof) as before.
        if ( @tokens > 1 ) {
            $self->_add_definition_for_word( $gloss_hashref, $_ ) for @tokens;
        }
        else {
            $gloss_hashref->{$word} = undef;
        }
    }
}

sub _add_to_dictionary {
    my ( $self, $xml ) = @_;

    my $dom = Mojo::DOM58->new($xml);

    # An entry should always have at least one kana reading ('reb'
    # element) and one English definition ('gloss' element), so skip
    # if either one is absent.
    # 'keb' = kanji reading
    my $kana_elems;
    return unless $kana_elems = $dom->find('reb');

    my @gloss_texts;
    return unless @gloss_texts = map $_->text, @{ $dom->find('gloss') };

    my $kanji_elems = $dom->find('keb');

    # We also want the part-of-speech (POS) tags (whether the word is a
    # noun, verb, etc.) May be more than one tag.

    # TODO What if no POS? Default to empty string?
    my $pos_elems = $dom->find('pos');
    $pos_elems = [ map $_->text, @$pos_elems ];

    for my $kana (@$kana_elems) {
        # Add to the kana_dict hashref.
        # Each kana key points to an arrayref of arrayrefs, with each of
        # these inner arrayrefs having an arrayref of POS tags as its first
        # element and an arrayref of glosses as its second.
        #
        # This innermost arrayref of glosses is for a particular kanji
        # reading (as a kana reading may map to multiple kanji readings,
        # e.g. 地震 and 自信 both map to じしん).
        #
        # The index of each new arrayref is used in the kanji dictionary
        # below.
        push @{ $self->kana_dict->{ $kana->text } },
            [ $pos_elems, \@gloss_texts ];

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

sub _tokenise {
    my $phrase = shift;

    my $mecab = Text::MeCab->new;

    my @words;
    for ( my $node = $mecab->parse($phrase); $node; $node = $node->next ) {
        my $surface_form = $node->surface;

        # First and last elements are empty so we do not want to include
        # those.
        # Text::MeCab evidently does some kind of encoding, as we have to
        # use decode_utf8 to avoid double-encoded strings.
        push @words, decode_utf8 $surface_form if $surface_form;
    }

    return @words;
}

1;
