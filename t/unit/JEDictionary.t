use lib '/home/vmihell-hale/nephila_nacrea/lib';

use JEDictionary;
use Test::More;

my $jed = JEDictionary->new(
    xml_file => '/home/vmihell-hale/dictionaries/JMdict_e' );

ok $jed->xml_file;

done_testing;
