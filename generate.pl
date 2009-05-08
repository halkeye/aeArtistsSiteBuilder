#!/usr/bin/perl -w

use warnings;
use strict;
use Template;
use Data::Dumper;
use Regexp::Common qw[Email::Address];
use File::Copy;

### MUST CHANGE
my @artists = qw(Greenishio); # Maires);

#my $OUTPUT_DIR = "/Users/halkeye/sshfs/meowcat/apache/vhosts/www.kodekoan.com/htdocs/files/ag2009";
my $OUTPUT_DIR = "/Users/halkeye/Sites/ae";

### LESS LIKELY TO CHANGE
my $THUMBNAIL_SIZE = 20;
my $SAMPLES_PER_ROW = 5;
my $CONVERT = "/opt/local/bin/convert";


### DON'T CHANGE ANYTHING

my $template = Template->new({
        'INCLUDE_PATH' => ['./templates/'],
        'PRE_PROCESS'  => 'real_header.tmpl',
        'POST_PROCESS' => 'real_footer.tmpl', 
        'POST_CHOMP'   => 1,
}) || die Template->error();

foreach my $artist (@artists)
{
    my $dir = "artists/$artist";
    print  STDERR "Processing $artist\n";
    if (!-e $dir)
    {
        print STDERR "Unable to read $artist, skipping\n";
        next;
    }

    my $vars = {
        'samplesPerRow' => $SAMPLES_PER_ROW,
        'artistName' => ucfirst($artist),
        'description' => '',
    };

    open(FH, "$dir/description.txt");
    $vars->{'description'} = do { local($/) = undef; <FH>; };
    close(FH);

    foreach my $ext (qw(png jpg gif jpeg bmp)) 
    {
        my $filename = $dir . "/avatar.$ext";
        next unless (-e $filename);
        $vars->{avatar} = $filename;
        last;
    }

    ####
    #### SAMPLES 
    ####
    $vars->{'samples'} = [];
    if (opendir(my $d, "$dir/samples/"))
    {
        while (my $file = readdir($d))
        {
            next unless $file =~ /\.(?:jpg|gif|png|jpeg|bmp)/i;
            push @{$vars->{'samples'}}, {'i'=>"$dir/samples/$file", 't'=>"$dir/samples/thumbs/$file"};
        }
        closedir($d);
    }


    #### 
    #### Links
    ####
    $vars->{'links'} = [];
    if (open(FH, "$dir/links.txt"))
    {
        while (<FH>)
        {
            if ($_ =~ /\S+/)
            {
                my ($link, $name) = split(/\|/);
                my ($email) = $link =~ /($RE{Email}{Address})/;
                $link = "mailto: $email" if ($email);

                push @{$vars->{'links'}}, {'name' => $name, 'link'=>$link};
            }
        }
        close(FH);
    }


    ####
    #### Output Artists Page
    ####
    
    my $output;
    $template->process('page.tmpl', $vars, \$output)
        || die $template->error();

    open(OUTPUT, ">", "$OUTPUT_DIR/$artist.html");
    print OUTPUT $output;
    close(OUTPUT);


    #### Output files
    {
        my $dir = $OUTPUT_DIR;
        foreach my $i (('artists',$artist,'samples','thumbs'))
        {
            $dir .= '/'.$i;
            mkdir($dir) unless (-e $dir);
        }
    }

    foreach my $sample (@{$vars->{'samples'}})
    {
        if (!-e "$OUTPUT_DIR/$sample->{'i'}")
        {
            print STDERR "Copying $artist sample\n";
            File::Copy::copy($sample->{'i'}, "$OUTPUT_DIR/$sample->{'i'}");
        }
        if (!-e "$OUTPUT_DIR/$sample->{'t'}")
        {
            print STDERR "Copying $artist thumb\n";
            system($CONVERT,"-thumbnail",$THUMBNAIL_SIZE, $sample->{'i'}, "$OUTPUT_DIR/$sample->{'t'}");
        }
    }
    if ($vars->{avatar})
    {
        print STDERR "Copying $artist avatar\n";
        File::Copy::copy($vars->{avatar}, "$OUTPUT_DIR/$vars->{avatar}")
            if (!-e "$OUTPUT_DIR/$vars->{avatar}");
    }
}
    
####
#### Output Main  Page
####

my $output;
$template->process('index.tmpl', { 'artists' => \@artists }, \$output)
    || die $template->error();

open(OUTPUT, ">", "$OUTPUT_DIR/index.html");
print OUTPUT $output;
close(OUTPUT);
