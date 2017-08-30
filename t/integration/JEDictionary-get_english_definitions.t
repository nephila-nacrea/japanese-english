use lib '../japanese-english/lib';

use strict;
use utf8;
use warnings;

use JEDictionary;
use Test2::V0;

# Test get_english_definitions
# for phrases

my $jed = JEDictionary->new;
$jed->build_dictionary_from_xml('../japanese-english/t/data/test-dict.xml');

is { $jed->get_english_definitions('地震自信') },
    {
    '地震' => {
        'じしん'    => ['earthquake'],
        'じぶるい' => ['earthquake'],
        'ない'       => ['earthquake'],
        'なえ'       => ['earthquake'],
    },
    '自信' =>
        { 'じしん' => [ 'self-confidence', 'confidence (in oneself)' ], },
    },
    'phrase tokenised and definitions found';

done_testing;
