#!/usr/bin/perl -w

use warnings;
use strict;
use Template;
use Data::Dumper;
use Regexp::Common qw[Email::Address];
use File::Copy;
use File::Basename ();

### MUST CHANGE
my %artists = (
    'Greenishio'     => 'Greenishio',
    'Maires'         => 'Maires',
    'redhalfdragon'  => 'Red Halfdragon',
    'Rinki'          => 'Rinki', 
    'Bandeau'        => 'Bandeau',
    'NivekOh'        => 'Nivek Oh',
    'Mandachan'      => 'Mandachan',
    'chun'           => 'Chun',
    'iruka'          => 'Iruka',
    'Lian'           => 'Lian',
    'AlexiusSan'     => 'AlexiusSan',
    'AsakuraMisakichi'=>'Asakura Misakichi',
    'knightcat'      =>'knightcat',
);

my $MODE = "FAKE_AE";

### LESS LIKELY TO CHANGE
my $THUMBNAIL_SIZE  = 50;
my $SAMPLES_PER_ROW = 10;
my $CONVERT = "/opt/local/bin/convert";

### DON'T CHANGE ANYTHING
#
my $params = {
    'INCLUDE_PATH' => ['./templates/'],
    'POST_CHOMP'   => 1,
};
my $OUTPUT_DIR;

if ($MODE eq "FAKE_AE")
{
    $OUTPUT_DIR = "/Users/halkeye/sshfs/meowcat/apache/vhosts/ae09ag.kodekoan.com/htdocs";
#    $OUTPUT_DIR = "/Users/halkeye/Sites/ae";
    $params->{'PRE_PROCESS'}  = 'real_header.tmpl';
    $params->{'POST_PROCESS'} = 'real_footer.tmpl'; 
}

sub defaultVars 
{
    return {
        'samplesPerRow' => $SAMPLES_PER_ROW,
        'description'   => '',
        'baseDir'  => '/files/ArtGallery/09/',
    };
}
    

my $template = Template->new($params) || die Template->error();
my @artistsVars;

foreach my $artist (keys %artists)
{
    my $dir = "artists/$artist";
    print  STDERR "Processing $artist\n";
    if (!-e $dir)
    {
        print STDERR "Unable to read $artist, skipping\n";
        next;
    }

    my $vars = defaultVars();
    $vars->{'artistName'}  = $artists{$artist};

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
    if (opendir(my $d, "$dir/samples/"))
    {
        $vars->{'samples'} = [];
        while (my $file = readdir($d))
        {
            next unless $file =~ /\.(?:jpg|gif|png|jpeg|bmp)/i;
            push @{$vars->{'samples'}}, {'i'=>$file, 't'=>"thumbs/$file", 'file'=>$file};
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


    #### Output files

    $vars->{'baseImageDir'} = $vars->{'baseDir'}.'artists/'.$artist.'/';
    system("mkdir", "-p", $OUTPUT_DIR.$vars->{'baseImageDir'})
        unless -e $OUTPUT_DIR.$vars->{'baseImageDir'};

    if (exists $vars->{'samples'})
    {
        foreach my $sample (@{$vars->{'samples'}})
        {
            my $origImage =  "$dir/samples/".$sample->{'i'};
            my $origThumb =  "$dir/samples/".$sample->{'t'};
            
            $sample->{'i'} = $vars->{'baseImageDir'}.$sample->{'i'};
            $sample->{'t'} = $vars->{'baseImageDir'}.$sample->{'t'};

            system("mkdir", "-p", $OUTPUT_DIR.File::Basename::dirname($sample->{'i'}))
                unless -e $OUTPUT_DIR.File::Basename::dirname($sample->{'i'});
            system("mkdir", "-p", $OUTPUT_DIR.File::Basename::dirname($sample->{'t'}))
                unless -e $OUTPUT_DIR.File::Basename::dirname($sample->{'t'});

            if (!-e $OUTPUT_DIR.$sample->{'i'})
            {
                print STDERR "Copying $artist sample\n";
                File::Copy::copy($origImage, $OUTPUT_DIR.$sample->{'i'});
            }
            if (!-e $OUTPUT_DIR.$sample->{'t'})
            {
                print STDERR "Copying $artist thumb\n";
                system($CONVERT,"-thumbnail",$THUMBNAIL_SIZE.'x'.$THUMBNAIL_SIZE, $origImage, $OUTPUT_DIR.$sample->{'t'});
            }
        }
    }

    my $origAvatar = $vars->{'avatar'};
    $vars->{'avatar'} = $vars->{'baseDir'}.$vars->{'avatar'};

    if ($vars->{avatar} && !-e $OUTPUT_DIR.$vars->{avatar})
    {
        system("mkdir", "-p", $OUTPUT_DIR.File::Basename::dirname($vars->{avatar}))
            unless -e $OUTPUT_DIR.File::Basename::dirname($vars->{avatar});
        print STDERR "Copying $artist avatar\n";
        File::Copy::copy($origAvatar, $OUTPUT_DIR.$vars->{avatar});
    }

    $vars->{'baseDir'} =~ s{/+$}{}g;
    ####
    #### Output Artists Page
    ####
    
    my $output;

    push @artistsVars, $vars;
    $template->process("page-6.tmpl", $vars, \$output)
        || die $template->error();

    open(OUTPUT, ">", "$OUTPUT_DIR/$artist.html");
    print OUTPUT $output;
    close(OUTPUT);

}
    
####
#### Output Main  Page
####

my $output;
$template->process('everyone.tmpl', { 'artists' => \@artistsVars }, \$output)
    || die $template->error();

open(OUTPUT, ">", "$OUTPUT_DIR/everyone.html");
print OUTPUT $output;
close(OUTPUT);

=cut
my $output;
$template->process('index.tmpl', { 'artists' => \@artists }, \$output)
    || die $template->error();

open(OUTPUT, ">", "$OUTPUT_DIR/index.html");
print OUTPUT $output;
close(OUTPUT);
