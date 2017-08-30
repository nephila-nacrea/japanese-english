use lib '../japanese-english/lib';

use strict;
use utf8;
use warnings;

use JEDictionary;
use Test2::V0;

#
# Test _add_to_dictionary
#
my $jed = new_dict();

$jed->_add_to_dictionary(
    '<entry>
    </entry>'
);

is $jed->kana_dict,  {}, 'Add empty entry to kana_dict';
is $jed->kanji_dict, {}, 'Add empty entry to kanji_dict';

# No keb (kanji entry)
$jed = new_dict();
$jed->_add_to_dictionary(
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

is $jed->kana_dict, { 'としとる' => [ ['to grow old'] ] },
    'Add entry with no kanji: kana_dict';
is $jed->kanji_dict, {}, 'Add entry with no kanji: kanji_dict';

# No reb (kana entry)
$jed = new_dict();
$jed->_add_to_dictionary(
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

is $jed->kana_dict,  {}, 'Add entry with no kana: kana_dict';
is $jed->kanji_dict, {}, 'Add entry with no kana: kanji_dict';

# No gloss
$jed = new_dict();
$jed->_add_to_dictionary(
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

is $jed->kana_dict,  {}, 'Add entry with no gloss: kana_dict';
is $jed->kanji_dict, {}, 'Add entry with no gloss: kanji_dict';

# One of each (keb & reb)
$jed = new_dict();
$jed->_add_to_dictionary(
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

is $jed->kana_dict, { 'としとる' => [ ['to grow old'] ] },
    'Add entry with one of each element: kana_dict';
is $jed->kanji_dict, { '年取る' => { 'としとる' => 0 } },
    'Add entry with one of each element: kanji_dict';

# Two of each (keb & reb)
$jed = new_dict();
$jed->_add_to_dictionary(
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

is $jed->kana_dict,
    {
    'としとる' => [ [ 'to grow old', 'to age' ] ],
    'トシトル' => [ [ 'to grow old', 'to age' ] ],
    },
    'Add entry with two of each element: kana_dict';
is $jed->kanji_dict,
    {
    '年取る' => { 'としとる' => 0, 'トシトル' => 0, },
    '歳取る' => { 'としとる' => 0, 'トシトル' => 0, },
    },
    'Add entry with two of each element: kanji_dict';

# Different kanji with same kana reading
$jed = new_dict();
$jed->_add_to_dictionary(
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
$jed->_add_to_dictionary(
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

is $jed->kana_dict,
    { 'じしん' => [ ['confidence'], ['earthquake'] ] },
    'Kanji with same kana reading: kana_dict';
is $jed->kanji_dict,
    {
    '自信' => { 'じしん' => 0 },
    '地震' => { 'じしん' => 1 },
    },
    'Kanji with same kana reading: kanji_dict';

# Identical kanji, different entries
$jed = new_dict();
$jed->_add_to_dictionary(
    '<entry>
    <ent_seq>1463770</ent_seq>
    <k_ele>
    <keb>日</keb>
    </k_ele>
    <k_ele>
    <keb>陽</keb>
    </k_ele>
    <r_ele>
    <reb>ひ</reb>
    </r_ele>
    <sense>
    <gloss>day</gloss>
    <gloss>days</gloss>
    </sense>
    <sense>
    <gloss>sun</gloss>
    <gloss>sunshine</gloss>
    <gloss>sunlight</gloss>
    </sense>
    <sense>
    <gloss>case (esp. unfortunate)</gloss>
    <gloss>event</gloss>
    </sense>
    </entry>'
);
$jed->_add_to_dictionary(
    '<entry>
    <ent_seq>2083100</ent_seq>
    <k_ele>
    <keb>日</keb>
    </k_ele>
    <r_ele>
    <reb>にち</reb>
    </r_ele>
    <sense>
    <gloss>Sunday</gloss>
    </sense>
    <sense>
    <gloss>day (of the month)</gloss>
    </sense>
    <sense>
    <gloss>counter for days</gloss>
    </sense>
    <sense>
    <gloss>Japan</gloss>
    </sense>
    </entry>'
);
$jed->_add_to_dictionary(
    '<entry>
    <ent_seq>2083110</ent_seq>
    <k_ele>
    <keb>日</keb>
    </k_ele>
    <r_ele>
    <reb>か</reb>
    </r_ele>
    <sense>
    <gloss>day of month</gloss>
    </sense>
    <sense>
    <gloss>counter for days</gloss>
    </sense>
    </entry>'
);

is $jed->kana_dict,
    {
    'か' => [ [ 'day of month', 'counter for days' ] ],
    'にち' =>
        [ [ 'Sunday', 'day (of the month)', 'counter for days', 'Japan' ] ],
    'ひ' => [
        [   'day', 'days', 'sun', 'sunshine', 'sunlight',
            'case (esp. unfortunate)', 'event',
        ]
    ],
    },
    'Identical kanji with different readings: kana_dict';
is $jed->kanji_dict,
    {
    '日' => {
        'か'    => 0,
        'ひ'    => 0,
        'にち' => 0,
    },
    '陽' => { 'ひ' => 0 },
    },
    'Identical kanji with different readings: kanji_dict';

sub new_dict { JEDictionary->new }

done_testing;
