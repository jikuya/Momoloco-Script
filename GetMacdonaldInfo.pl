#!/usr/bin/perl
use strict;
use utf8;
use Data::Dumper;
use Web::Scraper;
use LWP::UserAgent;
use URI::QueryParam;
use JSON;
use Encode;
use MongoDB;
use MongoDB::OID;

## ===========================================
## Define
## ===========================================
my $mongo_host = 'localhost';
my $mongo_port = 27017;
my $mongo_db   = 'momoloco';
my $mongo_col  = 'macdonald';

my $url_base    = 'http://www.mcdonalds.co.jp/shop/map/map.php?strcode=';
my $url_strcode = '';

my $debug = 0;

## ===========================================
## Setting Scraper
## ===========================================
my $scraper = scraper {
    process '/html/body/div/div[2]/div[2]/div[3]/div/div/div/h3', 'name' => 'TEXT';
    process '/html/body/div/div[2]/div[2]/div[3]/div[2]/div[2]/div/div/div/table/tr[2]/td', 'addr' => 'TEXT';
    process '/html/body/div/div[2]/div[2]/div[3]/div[2]/div[2]/div/div/div/table/tr[3]/td', 'tel' => 'TEXT';
    process '/html/body/div/div[2]/div[2]/div[3]/div[2]/div[2]/div/div[2]/div/table/tr[2]/td', 'weekday' => 'TEXT';
    process '/html/body/div/div[2]/div[2]/div[3]/div[2]/div[2]/div/div[2]/div/table/tr[3]/td', 'saturday' => 'TEXT';
    process '/html/body/div/div[2]/div[2]/div[3]/div[2]/div[2]/div/div[2]/div/table/tr[4]/td', 'holiday' => 'TEXT';
    process '/html/body/div/div[2]/div[2]/div[3]/div[2]/div[2]/div[2]/div[2]/div/div/p', 'remarks' => 'TEXT';
};
$scraper->user_agent(
    LWP::UserAgent->new(agent => "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)")
);

## ===========================================
## Execute
## ===========================================
my $i = 0;
while ( $i <= 48000 ) {
    ## ------------
    ## Make url
    ## ------------
    $url_strcode = sprintf("%05d", $i);
    my $url = $url_base . $url_strcode;
    ## ------------
    ## Get shop info
    ## ------------
    my $res = $scraper->scrape(URI->new($url));
    my $post = ();
    $post->{name}       = $res->{name};
    $post->{addr}       = $res->{addr};
    $post->{tel}        = $res->{tel};
    $post->{weekday}    = $res->{weekday};
    $post->{saturday}   = $res->{saturday};
    $post->{holiday}    = $res->{holiday};
    $post->{remarks}    = $res->{remarks};
    $post->{str_code}   = $url_strcode;
    $post->{str_url}    = $url;
    ## ------------
    ## If NotFound shop info
    ## ------------
    if (!defined($res->{name})) {
        sleep 1;
        $i++;
        next;
    }
    ## ------------
    ## Insert MongoDB
    ## ------------
    print Dumper($post) if ($debug);
    ## ------------
    ## Insert MongoDB
    ## ------------
    my $conn = MongoDB::Connection->new(host => "$mongo_host:$mongo_port");
    my $col  = $conn->$mongo_db->$mongo_col;
    my $id1  = $col->insert($post);
    ## ------------
    ## Sleep
    ## ------------
    sleep 1;
    ## ------------
    ## Increment
    ## ------------
    $i++;
}
