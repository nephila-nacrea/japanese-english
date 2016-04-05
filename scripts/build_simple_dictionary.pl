use lib '/home/vmihell-hale/nephila_nacrea/lib';
use strict;
use warnings;
use utf8;

use JEDictionary;

binmode STDOUT, ":utf8";

# Original dictionary file from http://www.edrdg.org/jmdict/edict_doc.html
# (JMdict_e.gz)
my $jed = JEDictionary->new(
    xml_file => '/home/vmihell-hale/dictionaries/JMdict_e' );
binmode DATA, ":utf8";
$jed->dump_perl_to_files(
    '/home/vmihell-hale/nephila_nacrea/data/kana-dict',
    '/home/vmihell-hale/nephila_nacrea/data/kanji-dict'
);

$jed->build_dictionary_from_xml;

$jed->dump_perl_to_files(
    '/home/vmihell-hale/nephila_nacrea/data/kana-dict',
    '/home/vmihell-hale/nephila_nacrea/data/kanji-dict'
);

# get_gloss($_) for qw/
#     過ごす
#     正社員
#     一泊
#     2回目
#     学部
#     学科
#     専攻
#     文の構成
#     理論
#     論理
#     倫理
#     脚本家
#     作家
#     現代文学
#     威厳
#     題名
#     探偵物語
#     あらすじ
#     サスペンス
#     読み終わる
#     死体
#     短編小説
#     代表的な作品
#     漢文
#     孔子
#     孟子
#     教え
#     いつも
#     壊れた
#     壊した
#     毎年
#     一石二鳥
#     作り話
#     植民地化
#     発言
#     意見
#     主観的
#     客観的
#     世界史
#     日本史
#     刺激的
#     普段の生活
#     普通の人生
#     伝記
#     複雑
#     制限
#     /;

sub get_gloss {
    my ($japanese_string) = @_;

    my $kana_hashref = $jed->kanji_dict->{$japanese_string};

    if ( keys %$kana_hashref ) {
        for my $kana ( keys %$kana_hashref ) {
            print "$kana\n";
            my $index = $kana_hashref->{$kana};
            print "\t$index\n";

            print "\t@{ $jed->kana_dict->{$kana}->[$index] }\n";
        }
    }
}
