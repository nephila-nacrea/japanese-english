use lib '/home/vmihell-hale/nephila_nacrea/lib';

use strict;
use warnings;

use JEDictionary;
use Test::More;

my $jed = new_dict();

$jed->add_to_dictionary(
    '<entry>
    </entry>'
);

is_deeply $jed->kana_dict,  {}, 'Add empty entry to kana_dict';
is_deeply $jed->kanji_dict, {}, 'Add empty entry to kanji_dict';

$jed = new_dict();

# No keb
$jed->add_to_dictionary(
    '<entry>
    <ent_seq>1468820</ent_seq>
    <r_ele>
    <reb>としとる</reb>
    </r_ele>
    <sense>
    <pos>&v5r;</pos>
    <pos>&vi;</pos>
    <gloss>to grow old</gloss>
    </sense>
    </entry>'
);

is_deeply $jed->kana_dict, { 'としとる' => [ ['to grow old'] ] },
    'Add entry with no kanji: kana_dict';
is_deeply $jed->kanji_dict, {}, 'Add entry with no kanji: kanji_dict';

$jed = new_dict();

# No reb
$jed->add_to_dictionary(
    '<entry>
    <ent_seq>1468820</ent_seq>
    <k_ele>
    <keb>年取る</keb>
    </k_ele>
    <sense>
    <pos>&v5r;</pos>
    <pos>&vi;</pos>
    <gloss>to grow old</gloss>
    </sense>
    </entry>'
);

is_deeply $jed->kana_dict,  {}, 'Add entry with no kana: kana_dict';
is_deeply $jed->kanji_dict, {}, 'Add entry with no kana: kanji_dict';

$jed = new_dict();

# No gloss
$jed->add_to_dictionary(
    '<entry>
    <ent_seq>1468820</ent_seq>
    <k_ele>
    <keb>年取る</keb>
    </k_ele>
    <r_ele>
    <reb>としとる</reb>
    </r_ele>
    <sense>
    <pos>&v5r;</pos>
    <pos>&vi;</pos>
    </sense>
    </entry>'
);

is_deeply $jed->kana_dict,  {}, 'Add entry with no gloss: kana_dict';
is_deeply $jed->kanji_dict, {}, 'Add entry with no gloss: kanji_dict';

$jed = new_dict();

# One of each
$jed->add_to_dictionary(
    '<entry>
    <ent_seq>1468820</ent_seq>
    <k_ele>
    <keb>年取る</keb>
    </k_ele>
    <r_ele>
    <reb>としとる</reb>
    </r_ele>
    <sense>
    <pos>&v5r;</pos>
    <pos>&vi;</pos>
    <gloss>to grow old</gloss>
    </sense>
    </entry>'
);

is_deeply $jed->kana_dict, { 'としとる' => [ ['to grow old'] ] },
    'Add entry with one of each element: kana_dict';
is_deeply $jed->kanji_dict, { '年取る' => { 'としとる' => 0 } },
    'Add entry with one of each element: kanji_dict';

$jed = new_dict();

# Two of each
$jed->add_to_dictionary(
    '<entry>
    <ent_seq>1468820</ent_seq>
    <k_ele>
    <keb>年取る</keb>
    </k_ele>
    <k_ele>
    <keb>歳取る</keb>
    </k_ele>
    <r_ele>
    <reb>としとる</reb>
    </r_ele>
    <r_ele>
    <reb>トシトル</reb>
    </r_ele>
    <sense>
    <pos>&v5r;</pos>
    <pos>&vi;</pos>
    <gloss>to grow old</gloss>
    <gloss>to age</gloss>
    </sense>
    </entry>'
);

is_deeply $jed->kana_dict,
    {
    'としとる' => [ [ 'to grow old', 'to age' ] ],
    'トシトル' => [ [ 'to grow old', 'to age' ] ],
    },
    'Add entry with two of each element: kana_dict';
is_deeply $jed->kanji_dict,
    {
    '年取る' => { 'としとる' => 0, 'トシトル' => 0, },
    '歳取る' => { 'としとる' => 0, 'トシトル' => 0, },
    },
    'Add entry with two of each element: kanji_dict';

$jed = new_dict();

# Different kanji with same kana reading
$jed->add_to_dictionary(
    '<entry>
    <ent_seq>1468820</ent_seq>
    <k_ele>
    <keb>自信</keb>
    </k_ele>
    <r_ele>
    <reb>じしん</reb>
    </r_ele>
    <sense>
    <gloss>confidence</gloss>
    </sense>
    </entry>'
);
$jed->add_to_dictionary(
    '<entry>
    <ent_seq>1468820</ent_seq>
    <k_ele>
    <keb>地震</keb>
    </k_ele>
    <r_ele>
    <reb>じしん</reb>
    </r_ele>
    <sense>
    <gloss>earthquake</gloss>
    </sense>
    </entry>'
);

is_deeply $jed->kana_dict,
    { 'じしん' => [ ['confidence'], ['earthquake'], ], },
    'Kanji with same kana reading: kana_dict';
is_deeply $jed->kanji_dict,
    {
    '自信' => { 'じしん' => 0 },
    '地震' => { 'じしん' => 1 },
    },
    'Kanji with same kana reading: kanji_dict';

sub new_dict {
    return JEDictionary->new(
        xml_file => '/home/vmihell-hale/dictionaries/JMdict_e' );
}

done_testing;
