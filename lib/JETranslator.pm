package JETranslator;

use lib '../japanese-english/lib';

use strict;
use warnings;

use JEDictionary;
use Moo;
use Text::CSV;
use Text::MeCab;
use Unicode::UTF8 'decode_utf8';

has dictionary => ( is => 'rw', default => sub { JEDictionary->new } );

sub translate {
    my ( $self, $sentence ) = @_;

    # TODO
}

# Get hash of definitions, given a list of Japanese words
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
    #       [<glosses_1>], ...,
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
            my @glosses = @{ $gloss_hash{$key} };
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
    # { <kana_reading> => <entry_key>, ... }
    if ( my $kana_href = $self->dictionary->kanji_dict->{$word} ) {
        # There may be several kana readings for a kanji, which
        # may or may not share the same glosses.
        # Just get the glosses for each one, though there may be
        # repetition.
        for my $kana ( keys %$kana_href ) {
            my $entry_key = $kana_href->{$kana};

            # Find gloss(es) in kana dictionary. Ignore sense boundaries
            # and POS tags.
            my $senses = $self->dictionary->kana_dict->{$kana}{$entry_key};

            push @{ $gloss_hashref->{$word}{$kana} }, @{ $_->[1] }
                for values %$senses;
        }
    }
    elsif ( my $entries = $self->dictionary->kana_dict->{$word} ) {
        # Word not found in kanji dictionary;
        # is written in kana alone.
        # So just get all glosses for that kana entry.
        # Ignore entry and sense boundaries, and POS tags.
        for my $senses ( values %$entries ) {
            push @{ $gloss_hashref->{$word} }, @{ $_->[1] }
                for values %$senses;
        }
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
        push @words, $surface_form if $surface_form;
    }

    return @words;
}

1;
