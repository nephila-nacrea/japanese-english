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
    if ( my $kana_href = $self->kanji_dict->{$word} ) {
        # There may be several kana readings for a kanji, which
        # may or may not share the same glosses.
        # Just get the glosses for each one, though there may be
        # repetition.
        for my $kana ( keys %$kana_href ) {
            my $entry_key = $kana_href->{$kana};

            # Find gloss(es) in kana dictionary. Ignore sense boundaries
            # and POS tags.
            my $senses = $self->kana_dict->{$kana}{$entry_key};

            push @{ $gloss_hashref->{$word}{$kana} }, @{ $_->[1] }
                for values %$senses;
        }
    }
    elsif ( my $entries = $self->kana_dict->{$word} ) {
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

sub _add_to_dictionary {
    my ( $self, $xml ) = @_;

    my $dom = Mojo::DOM58->new($xml);

    # An entry should always have at least one kana reading ('reb'
    # element) and one English definition (within 'sense' element), so skip
    # if either one is absent.
    # 'keb' = kanji reading
    my $kana_elems;
    return unless $kana_elems = $dom->find('reb');

    my $kanji_elems = $dom->find('keb');

    my @sense_nodes;

    # If no sense nodes or gloss nodes, return
    return unless @sense_nodes = @{ $dom->find('sense') };
    return unless @{ $dom->find('gloss') };

    # %sense_data is of form
    # sense_1 =>  [
    #       [
    #           pos_1, pos_2, ...
    #       ],
    #       [
    #           gloss_1, gloss_2, ...
    #       ],
    #   ],
    #   sense_2 => [
    #       ...
    #   ],
    # )
    my %sense_data;

    my $index = 1;
    for my $sense_node (@sense_nodes) {
        my @gloss_texts;
        next
            unless @gloss_texts = map $_->text,
            @{ $sense_node->find('gloss') };

        my @pos_texts = map _pos_mapping( $_->text ),
            @{ $sense_node->find('pos') };

        # If a sense node does not have its own POS tags, steal from its
        # first sibling
        @pos_texts = @{ $sense_data{sense_1}[0] // [] } unless @pos_texts;

        $sense_data{"sense_$index"} = [ \@pos_texts, \@gloss_texts ];

        $index++;
    }

    for my $kana (@$kana_elems) {
        # Am now using hashrefs as well as arrayrefs, for readability (though
        # there is probably loss of efficiency).
        #
        # Add to the kana_dict hashref.
        # Each kana key points to a hashref of entries.
        # Each entry is a hashref of senses.
        # Each sense is an arrayref, with an arrayref of POS tags as its first
        # element and an arrayref of glosses as its second.
        #
        # This innermost arrayref of glosses is for a particular kanji
        # reading (as a kana reading may map to multiple kanji readings,
        # e.g. 地震 and 自信 both map to じしん).
        #
        # Entry keys (that point to hashrefs of senses) are used in the kanji
        # dictionary below.

        my $entry_index = 1;
        $entry_index++
            while
            exists $self->kana_dict->{ $kana->text }->{"entry_$entry_index"};

        $self->kana_dict->{ $kana->text }->{"entry_$entry_index"}
            = \%sense_data;

        for my $kanji (@$kanji_elems) {
            # Add to the kanji_dict hashref.
            # Each value is a hashref mapping a kana reading to its entry key.
            # So e.g. if you were to look up 地震 in the kanji dictionary,
            # you would get a kana reading of じしん and a key of entry_*;
            # the kana and key can be used to look up the correct English
            # gloss(es) in the kana dictionary (e.g. 'earthquake' as opposed
            # to 'confidence').
            # A kanji entry may have more than one kana reading.
            $self->kanji_dict->{ $kanji->text }->{ $kana->text }
                = "entry_$entry_index";
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

sub _pos_mapping {
    # XML dictionary (JMdict_e) maps <pos> tag contents to entities. So e.g.
    # '&n;' becomes 'noun (common) (futsuumeishi)'.
    # Since I do not want to work with these long strings, I convert them
    # back into short tags.
    my %mapping = (
        "`kari' adjective (archaic)"                           => 'adj-kari',
        "`ku' adjective (archaic)"                             => 'adj-ku',
        "`shiku' adjective (archaic)"                          => 'adj-shiku',
        "`taru' adjective"                                     => 'adj-t',
        "adverb taking the `to' particle"                      => 'adv-to',
        "children's language"                                  => 'chn',
        "Godan verb with `bu' ending"                          => 'v5b',
        "Godan verb with `gu' ending"                          => 'v5g',
        "Godan verb with `ku' ending"                          => 'v5k',
        "Godan verb with `mu' ending"                          => 'v5m',
        "Godan verb with `nu' ending"                          => 'v5n',
        "Godan verb with `ru' ending (irregular verb)"         => 'v5r-i',
        "Godan verb with `ru' ending"                          => 'v5r',
        "Godan verb with `su' ending"                          => 'v5s',
        "Godan verb with `tsu' ending"                         => 'v5t',
        "Godan verb with `u' ending (special class)"           => 'v5u-s',
        "Godan verb with `u' ending"                           => 'v5u',
        "Nidan verb (lower class) with `bu' ending (archaic)"  => 'v2b-s',
        "Nidan verb (lower class) with `dzu' ending (archaic)" => 'v2d-s',
        "Nidan verb (lower class) with `gu' ending (archaic)"  => 'v2g-s',
        "Nidan verb (lower class) with `hu/fu' ending (archaic)" => 'v2h-s',
        "Nidan verb (lower class) with `ku' ending (archaic)"    => 'v2k-s',
        "Nidan verb (lower class) with `mu' ending (archaic)"    => 'v2m-s',
        "Nidan verb (lower class) with `nu' ending (archaic)"    => 'v2n-s',
        "Nidan verb (lower class) with `ru' ending (archaic)"    => 'v2r-s',
        "Nidan verb (lower class) with `su' ending (archaic)"    => 'v2s-s',
        "Nidan verb (lower class) with `tsu' ending (archaic)"   => 'v2t-s',
        "Nidan verb (lower class) with `u' ending and `we' conjugation (archaic)"
            => 'v2w-s',
        "Nidan verb (lower class) with `yu' ending (archaic)"    => 'v2y-s',
        "Nidan verb (lower class) with `zu' ending (archaic)"    => 'v2z-s',
        "Nidan verb (upper class) with `bu' ending (archaic)"    => 'v2b-k',
        "Nidan verb (upper class) with `dzu' ending (archaic)"   => 'v2d-k',
        "Nidan verb (upper class) with `gu' ending (archaic)"    => 'v2g-k',
        "Nidan verb (upper class) with `hu/fu' ending (archaic)" => 'v2h-k',
        "Nidan verb (upper class) with `ku' ending (archaic)"    => 'v2k-k',
        "Nidan verb (upper class) with `mu' ending (archaic)"    => 'v2m-k',
        "Nidan verb (upper class) with `ru' ending (archaic)"    => 'v2r-k',
        "Nidan verb (upper class) with `tsu' ending (archaic)"   => 'v2t-k',
        "Nidan verb (upper class) with `yu' ending (archaic)"    => 'v2y-k',
        "Nidan verb with 'u' ending (archaic)"                   => 'v2a-s',
        "nouns which may take the genitive case particle `no'"   => 'adj-no',
        "Yodan verb with `bu' ending (archaic)"                  => 'v4b',
        "Yodan verb with `gu' ending (archaic)"                  => 'v4g',
        "Yodan verb with `hu/fu' ending (archaic)"               => 'v4h',
        "Yodan verb with `ku' ending (archaic)"                  => 'v4k',
        "Yodan verb with `mu' ending (archaic)"                  => 'v4m',
        "Yodan verb with `nu' ending (archaic)"                  => 'v4n',
        "Yodan verb with `ru' ending (archaic)"                  => 'v4r',
        "Yodan verb with `su' ending (archaic)"                  => 'v4s',
        "Yodan verb with `tsu' ending (archaic)"                 => 'v4t',
        'abbreviation'                                           => 'abbr',
        'abbreviation'                                           => 'abbr',
        'adjectival nouns or quasi-adjectives (keiyodoshi)'      => 'adj-na',
        'adjective (keiyoushi) - yoi/ii class'                   => 'adj-ix',
        'adjective (keiyoushi)'                                  => 'adj-i',
        'adverb (fukushi)'                                       => 'adv',
        'adverbial noun (fukushitekimeishi)'                     => 'n-adv',
        'adverbial noun (fukushitekimeishi)'                     => 'n-adv',
        'anatomical term'                                        => 'anat',
        'archaic/formal form of na-adjective'  => 'adj-nari',
        'archaism'                             => 'arch',
        'architecture term'                    => 'archit',
        'astronomy, etc. term'                 => 'astron',
        'ateji (phonetic) reading'             => 'ateji',
        'auxiliary adjective'                  => 'aux-adj',
        'auxiliary verb'                       => 'aux-v',
        'auxiliary'                            => 'aux',
        'baseball term'                        => 'baseb',
        'biology term'                         => 'biol',
        'botany term'                          => 'bot',
        'Buddhist term'                        => 'Buddh',
        'business term'                        => 'bus',
        'chemistry term'                       => 'chem',
        'colloquialism'                        => 'col',
        'computer terminology'                 => 'comp',
        'conjunction'                          => 'conj',
        'copula'                               => 'cop-da',
        'counter'                              => 'ctr',
        'counter'                              => 'ctr',
        'derogatory'                           => 'derog',
        'economics term'                       => 'econ',
        'engineering term'                     => 'engr',
        'exclusively kana'                     => 'ek',
        'exclusively kanji'                    => 'eK',
        'expressions (phrases, clauses, etc.)' => 'exp',
        'familiar language'                    => 'fam',
        'female term or language'              => 'fem',
        'finance term'                         => 'finc',
        'food term'                            => 'food',
        'geology, etc. term'                   => 'geol',
        'geometry term'                        => 'geom',
        'gikun (meaning as reading) or jukujikun (special kanji reading)' =>
            'gikun',
        'Godan verb - -aru special class'                   => 'v5aru',
        'Godan verb - Iku/Yuku special class'               => 'v5k-s',
        'Godan verb - Uru old class verb (old form of Eru)' => 'v5uru',
        'Hokkaido-ben'                                      => 'hob',
        'honorific or respectful (sonkeigo) language'       => 'hon',
        'humble (kenjougo) language'                        => 'hum',
        'Ichidan verb - kureru special class'               => 'v1-s',
        'Ichidan verb - zuru verb (alternative form of -jiru verbs)' => 'vz',
        'Ichidan verb'                                               => 'v1',
        'idiomatic expression'                                       => 'id',
        'interjection (kandoushi)'                                   => 'int',
        'intransitive verb'                                          => 'vi',
        'irregular nu verb'                                          => 'vn',
        'irregular okurigana usage'                                  => 'io',
        'irregular ru verb, plain form ends with -ri'                => 'vr',
        'irregular verb'                                             => 'iv',
        'jocular, humorous term'                                     => 'joc',
        'Kansai-ben'                                                 => 'ksb',
        'Kantou-ben'                                                 => 'ktb',
        'Kuru verb - special class'                                  => 'vk',
        'Kyoto-ben'                                                  => 'kyb',
        'Kyuushuu-ben'                                               => 'kyu',
        'law, etc. term'                                             => 'law',
        'linguistics terminology'                           => 'ling',
        'mahjong term'                                      => 'mahj',
        'male slang'                                        => 'male-sl',
        'male term or language'                             => 'male',
        'manga slang'                                       => 'm-sl',
        'martial arts term'                                 => 'MA',
        'mathematics'                                       => 'math',
        'medicine, etc. term'                               => 'med',
        'military'                                          => 'mil',
        'music term'                                        => 'music',
        'Nagano-ben'                                        => 'nab',
        'noun (common) (futsuumeishi)'                      => 'n',
        'noun (common) (futsuumeishi)'                      => 'n',
        'noun (temporal) (jisoumeishi)'                     => 'n-t',
        'noun (temporal) (jisoumeishi)'                     => 'n-t',
        'noun or participle which takes the aux. verb suru' => 'vs',
        'noun or participle which takes the aux. verb suru' => 'vs',
        'noun or verb acting prenominally'                  => 'adj-f',
        'noun, used as a prefix'                            => 'n-pref',
        'noun, used as a prefix'                            => 'n-pref',
        'noun, used as a suffix'                            => 'n-suf',
        'noun, used as a suffix'                            => 'n-suf',
        'noun, used as a suffix'                            => 'n-suf',
        'numeric'                                           => 'num',
        'obscure term'                                      => 'obsc',
        'obsolete term'                                     => 'obs',
        'old or irregular kana form'                        => 'oik',
        'onomatopoeic or mimetic word'                      => 'on-mim',
        'Osaka-ben'                                         => 'osb',
        'out-dated or obsolete kana usage'                  => 'ok',
        'out-dated or obsolete kana usage'                  => 'ok',
        'particle'                                          => 'prt',
        'physics terminology'                               => 'physics',
        'poetical term'                                     => 'poet',
        'polite (teineigo) language'                        => 'pol',
        'pre-noun adjectival (rentaishi)'                   => 'adj-pn',
        'prefix'                                            => 'pref',
        'pronoun'                                           => 'pn',
        'proper noun'                                       => 'n-pr',
        'proverb'                                           => 'proverb',
        'rare'                                              => 'rare',
        'rude or X-rated term (not displayed in educational software)' => 'X',
        'Ryuukyuu-ben'                           => 'rkb',
        'sensitive'                              => 'sens',
        'Shinto term'                            => 'Shinto',
        'shogi term'                             => 'shogi',
        'slang'                                  => 'sl',
        'sports term'                            => 'sports',
        'su verb - precursor to the modern suru' => 'vs-c',
        'suffix'                                 => 'suf',
        'sumo term'                              => 'sumo',
        'suru verb - irregular'                  => 'vs-i',
        'suru verb - special class'              => 'vs-s',
        'Tosa-ben'                               => 'tsb',
        'Touhoku-ben'                            => 'thb',
        'transitive verb'                        => 'vt',
        'Tsugaru-ben'                            => 'tsug',
        'unclassified'                           => 'unc',
        'verb unspecified'                       => 'v-unspec',
        'vulgar expression or word'              => 'vulg',
        'word containing irregular kana usage'   => 'ik',
        'word containing irregular kanji usage'  => 'iK',
        'word containing out-dated kanji'        => 'oK',
        'word usually written using kana alone'  => 'uk',
        'word usually written using kanji alone' => 'uK',
        'yojijukugo'                             => 'yoji',
        'zoology term'                           => 'zool',
    );

    return $mapping{ +shift } || '';
}

1;
