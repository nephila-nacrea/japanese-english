use lib '../japanese-english/lib';

use strict;
use utf8;
use warnings;

use Text::MeCab;

my $mecab = Text::MeCab->new;

for (
    my $node = $mecab->parse(
        '香川県においてうどんは地元で特に好まれている料理であり、一人あたりの消費量も日本全国の都道府県別統計においても第1位である[1]。料理等に地域名を冠してブランド化する地域ブランドの1つとしても、観光客の増加、うどん生産量の増加、知名度注目度の上昇などの効果をもたらし、地域ブランド成功例の筆頭に挙げられる[2]。日経リサーチの隔年調査では地域ブランドの総合力において350品目中1位となり（2008年、2010年連続）[3]、観光客は行き先選択の理由、香川の魅力の第一にうどんを挙げ[4]、2011年には香川県庁と香川県観光協会はうどんを全面的に推しだした観光キャンペーン「うどん県」[5]をスタートさせた。'
    );
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
