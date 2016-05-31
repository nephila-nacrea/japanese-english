use lib '/home/vmihell-hale/nephila_nacrea/lib';
use strict;
use warnings;
use utf8;

use JEDictionary;

my $jed = JEDictionary->new;
$jed->build_dictionary_from_perl(
    '/home/vmihell-hale/nephila_nacrea/data/kana-dict',
    '/home/vmihell-hale/nephila_nacrea/data/kanji-dict',
);

my @words = qw/脚本
    工夫
    語学プログラム
    医療関係
    無心
    邪念
    精進料理
    労働ビザ
    方言
    エサ
    後悔
    海外留学生
    郷土料理
    人脈
    妥協 だきょう
    体を動かす
    体がなまる
    ジムに通う
    体が衰える
    平常心
    隔離
    馴染む
    攻撃
    投票
    監視
    戦略
    身近に感じる
    地区
    人事に思えない
    無実
    巻き込む
    現実
    判断
    無知
    習慣
    中立的
    中東
    転々としました
    アラブ首長共和国
    兄弟姉妹
    義理のお母さん
    確かではない
    出産祝いのプレゼント
    五行
    恵む
    役割
    例外/;

my %gloss_hash = $jed->get_english_definitions(@words);

$jed->print_to_csv( '/home/vmihell-hale/nephila_nacrea/data/result-1',
    %gloss_hash );
