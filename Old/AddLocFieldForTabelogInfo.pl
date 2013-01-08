#!/usr/bin/perl
use strict;
use utf8;
use Tie::IxHash;
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
my $mongo_col  = 'point';

my $google_map_geo_url = 'http://maps.google.com/maps/geo';
my $google_map_api_key = 'ABQIAAAAY7WrwEvnj5MzQ53HSduoZxTGUeZekLo8tKJ4I2JH-Ar4EQD8QxSmLbV2pmQWFEsJ55l5Z32uNVcIIg';

## ===========================================
## Execute
## ===========================================
## ------------
## Get All Point Info From MongoDB
## ------------
my $conn = MongoDB::Connection->new(host => "$mongo_host:$mongo_port");
my $col  = $conn->$mongo_db->$mongo_col;
my $all_points = $col->find->sort({ "_id" => 1 });;
while ( my $point = $all_points->next) {
    ## ------------
    ## Add "loc" field
    ## ------------
    #next if (!$point->{lat});
    my %loc = ();
    %loc = { lng => $point->{loc}->{lng}, lat => $point->{loc}->{lat} };
    sort keys %loc;
    #$point->{loc} = { lng => $point->{loc}->{lng}, lat => $point->{loc}->{lat} };
    $point->{loc} = %loc;
    #delete $point->{lat};
    #delete $point->{lng};
print Dumper($point);
exit;
    $col->save($point);
}

