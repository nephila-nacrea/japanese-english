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
    <pos>Godan verb with `ru\' ending</pos>
    <pos>intransitive verb</pos>
    <gloss>to grow old</gloss>
    </sense>
    </entry>'
);

is $jed->kana_dict,
    { 'としとる' =>
        { entry_1 => { sense_1 => [ [qw/v5r vi/], ['to grow old'] ] } } },
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
    <pos>Godan verb with `ru\' ending</pos>
    <pos>intransitive verb</pos>
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
    <pos>Godan verb with `ru\' ending</pos>
    <pos>intransitive verb</pos>
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
    <pos>Godan verb with `ru\' ending</pos>
    <pos>intransitive verb</pos>
    <gloss>to grow old</gloss>
    </sense>
    </entry>'
);

is $jed->kana_dict,
    { 'としとる' =>
        { entry_1 => { sense_1 => [ [qw/v5r vi/], ['to grow old'] ] } } },
    'Add entry with one of each element: kana_dict';
is $jed->kanji_dict, { '年取る' => { 'としとる' => 'entry_1' } },
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
    <pos>Godan verb with `ru\' ending</pos>
    <pos>intransitive verb</pos>
    <gloss>to grow old</gloss>
    <gloss>to age</gloss>
    </sense>
    </entry>'
);

is $jed->kana_dict,
    {
    'としとる' => {
        entry_1 =>
            { sense_1 => [ [qw/v5r vi/], [ 'to grow old', 'to age' ] ] }
    },
    'トシトル' => {
        entry_1 =>
            { sense_1 => [ [qw/v5r vi/], [ 'to grow old', 'to age' ] ] }
    },
    },
    'Add entry with two of each element: kana_dict';
is $jed->kanji_dict,
    {
    '年取る' =>
        { 'としとる' => 'entry_1', 'トシトル' => 'entry_1', },
    '歳取る' =>
        { 'としとる' => 'entry_1', 'トシトル' => 'entry_1', },
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
    {
    'じしん' => {
        entry_1 => { sense_1 => [ [], ['confidence'] ] },
        entry_2 => { sense_1 => [ [], ['earthquake'] ] },
    }
    },
    'Kanji with same kana reading: kana_dict';
is $jed->kanji_dict,
    {
    '自信' => { 'じしん' => 'entry_1' },
    '地震' => { 'じしん' => 'entry_2' },
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
    'か' => {
        entry_1 => {
            sense_1 => [ [], ['day of month'] ],
            sense_2 => [ [], ['counter for days'] ],
        }
    },
    'にち' => {
        entry_1 => {
            sense_1 => [ [], ['Sunday'] ],
            sense_2 => [ [], ['day (of the month)'] ],
            sense_3 => [ [], ['counter for days'] ],
            sense_4 => [ [], ['Japan'] ],
        }
    },
    'ひ' => {
        entry_1 => {
            sense_1 => [ [], [ 'day', 'days' ] ],
            sense_2 => [ [], [ 'sun', 'sunshine', 'sunlight' ] ],
            sense_3 => [ [], [ 'case (esp. unfortunate)', 'event' ] ],
        }
    },
    },
    'Identical kanji with different readings: kana_dict';
is $jed->kanji_dict,
    {
    '日' => {
        'か'    => 'entry_1',
        'ひ'    => 'entry_1',
        'にち' => 'entry_1',
    },
    '陽' => { 'ひ' => 'entry_1' },
    },
    'Identical kanji with different readings: kanji_dict';

sub new_dict { JEDictionary->new( no_dictionary_build => 1 ) }

done_testing;
