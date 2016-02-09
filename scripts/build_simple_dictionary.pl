# Make simplified dictionary
# Original is ~/dictionaries/edict2.utf

# Starting from line 2 onwards:
# Each line starts with kanji reading (may also include kana)
# Multiple readings separated by ';'
# Kanji readings may be followed by explanatory label in '()' - ignore these
# Then space
# If no kanji reading, then kana instead

# Then square brackets with kana
    # Multiple kana readings separated by ';'
    # Each reading may be followed by explanatory label in '()' - ignore
# Then space
# Then '/'
# Then definition, including POS tags etc.
# Ends with '/EntL......./'

my $line = qr!([^\[]*)(\[.*\])?/(.*)/EntL\w+/!

my $first_readings = $1;
my $kana_readings = $2;
my $definition = $3;