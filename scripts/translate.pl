use lib '../japanese-english/lib';

use strict;
use utf8;
use warnings;

use Text::MeCab;

my $mecab = Text::MeCab->new;

for (
    my $node = $mecab->parse('私の名前はビクトリアです');
    $node;
    $node = $node->next
    )
{
    use Data::Dumper;
    $Data::Dumper::Indent = 2;
    warn Dumper 'id: ' . $node->id;
    warn Dumper 'surface: ' . $node->surface;
    warn Dumper 'length: ' . $node->length;
    warn Dumper 'rlength: ' . $node->rlength;
    warn Dumper 'feature: ' . $node->feature;
    warn Dumper 'rcattr: ' . $node->rcattr;
    warn Dumper 'lcattr: ' . $node->lcattr;
    warn Dumper 'stat: ' . $node->stat;
    warn Dumper 'isbest: ' . $node->isbest;
    warn Dumper 'alpha: ' . $node->alpha;
    warn Dumper 'beta: ' . $node->beta;
    warn Dumper 'prob: ' . $node->prob;
    warn Dumper 'wcost: ' . $node->wcost;
    warn Dumper 'cost: ' . $node->cost;

    # # First and last elements are empty so we do not want to include
    # # those.
    # # Text::MeCab evidently does some kind of encoding, as we have to
    # # use decode_utf8 to avoid double-encoded strings.
    # push @words, decode_utf8 $surface_form if $surface_form;
}
