use strict;
use warnings;
use 5.14.1;
use Data::Dumper;

my $contents; # = do { local $/; <DATA> };
my $file = $ARGV[0];
my $path = 'jpg/';
#print $contents;
my $image = $path. $ARGV[0] . '.jpg';
if (! -f $image) {
    say "$image does not exist";
    exit;
}
else {
    print "Attempting ocr on $image...";
    $contents = do_ocr($image);
    say "done!";
}

if (!$contents) {
    say "Error extracting text from $image, quitting.";
    exit;
}

my @people = $contents =~ /(^\w+):/mg;

my %people;
@people{@people} = (1) x @people; #uniquify people

my $people_regexp = join "|", keys %people;
my $row = "";
my $spoken = 1;
my $html = <<HEADER;
<html>
  <meta charset="UTF-8">
  <head>
    <title></title>
    <style type="text/css">
    body { font-family: arial; font-size: 10pt; color:#333; }
    table, th, td { border: 1px solid #999; font-size: 10pt; }
    tr:nth-child(even) { background-color: #f2f2f2; }
    th, td { padding: 5px; }
    table { width: 600px; margin: auto; border-collapse: collapse;}
    audio { width: 600px; display:block; margin: 5px auto 5px auto;}
    </style>
  </head>
  <body>
HEADER
$html .= "<table><tr>";

my $text = "";
my @lines = split "\n", $contents;
my $header;
my $count = 0;
#one or more lines till the dialog begins are chapter heading(s).
for my $line (@lines) {
    #say $line;
    #<STDIN>;
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;

    if ($line =~ /^($people_regexp):/) {
        last;
    }
    else {
        $header .= " " . $line;
        $count++;
        #shift(@lines);
    }
}

if ($header) {
    $header =~ s/^\s+//;
    $header =~ s/\s+$//;
    $html .= "<th colspan='2'>$header</th></tr><tr>";
}

for my $line (@lines[$count..$#lines]) { #skip the header lines
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    next if ($line =~ /^\(\.\.\.\)$/); #(...) pauses in the text. They don't add much
    if ($line =~ /^\(.*\)$/) { #pauses between dialog get their own row.
        $text .= $row . "\n";
        # $text .= $line . "\n";  #uncomment to include the pauses in the audio
        $html .= "$row</td></tr>";
        $html .= "<tr><td colspan='2'>$line</td></tr><tr>";
        $row = "";
    }
    else {
        if ($line =~ /^($people_regexp):?/) {
            #say $row if $row ne "";
            if ($row ne "") {
                $html .= "$row</td></tr><tr>";
                $text .= $row . "\n";
            }
            #speak($row) if $row ne "";
            my $person = $1;
            $html .= "<td>$person</td><td>";
            $line =~ s/^$person:?\s+//;
            $row = $line;
        }
        else {
            #say "[$row]";
            if ($row !~ /—$/) {
                $row .= ". ";
            }
            else {
                $row =~ s/—$//;
            }
            $row .= $line;
        }
    }
}

$html .= "$row</td></tr>";
$html .= "</table>";
$html .= "<audio controls><source src='../audio/mp3/$file.mp3'></audio>";
$html .= "</body></html>";

$text .= $row;

write_html($html);
make_audio($text, $file);
encode_audio($file);

sub do_ocr {
    my $image = shift;
    my $content = `tesseract $image -psm 6 -l nld stdout 2>/dev/null`;
    return do_corrections($content);
}

sub write_html {
    my $html = shift;
    print "Writing html...";

    open my $fh, '>', "html/$file.html" || die $!;
    print $fh $html;
    close $fh;

    say "done!";
}

sub make_audio {
    my ($text, $file) = @_;
    print "Making audio file...";

    system "say", ('-v', 'Xander', '-o', "audio/pcm/$file.aiff", $text);

    say "done!";
}

sub encode_audio {
    my $file = shift;
    print "Encoding to mp3...";

    system "ffmpeg", ('-v', '-8', '-y', '-i', "audio/pcm/$file.aiff", '-c:a', 'libmp3lame', '-b:a', '128k', "audio/mp3/$file.mp3");

    say "done!";
}

sub speak {
    system "say", ("-i", "-v", "Xander", "$_[0]");
}

sub do_corrections {
    my $text = shift;
    my %corrections = (
        'Engeiand' => 'Engeland',
        '0\,' => 'O,',
        'haan' => 'haar.',
        'la:' => 'Ja!',
        'SUS\)"' => 'Susy:',
    );

    for my $key (keys %corrections) {
        $text =~ s/$key/$corrections{$key}/msg;
    }

    return $text;
}
#say Dumper(\%people);

__DATA__
Docent: Goedemorgen allemaal.
Welkom in de cursus Nederlands.
Ik ben Karin Dijkstra en ik ben jullie docent.
Jullie hebben twee docenten. De andere docent is Paul de Vries. Hij
geeft twee dagen les en ik drie.
We beginnen met kennismaken.
Wie ben jij? Wat is jouw naam?
Cursist: Ik ben Susy. Mijn naam is Susy.
Docent: Dag Susy. Susy is je voornaam en wat is je achternaam?
Susy: Mijn achternaam is Wall.
Docent: Uit welk land kom je?
Susy: Ik kom uit Engeiand.
Docent: De buurman van Susy: Wie ben jij? Hoe heet jij?
Buurman: Ik heet Ning.
Docent: Dag Ning. En waar kom je vandaan?
Ning: Ik kom uit China.
Docent: Waar woon je?
Ning: Ik woon nu in Utrecht.
Docent: Wat is je adres?
Ning: Mijn adres is Hofstraat 22.
Docent: Op welk nummer? 23?
Ning: Nee, op 22. En mijn postcode is 3581 TW in Utrecht.
En u mevrouw? Woont u ookin Utrecht?
Docent: Zeg maar jij, hoor. Ja, ik woon hier al twintig jaar.
Oké, we gaan verder met de les. Heeft iedereen het boek en de cd?
We beginnen met tekst 1 op bladzijde 8. We luisteren naar de tekst.;
We stoppen even, het is pauze. Tot straks. '- *

