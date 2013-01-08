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
my $all_points = $col->find({lat => ""})->sort({ "_id" => 1 });;
while ( my $point = $all_points->next) {
    ## ------------
    ## process addr info
    ## ------------
    $point->{addr} =~ s/\s+//g;

    ## ------------
    ## get latitude & longitude
    ## ------------
    my $geo_uri = URI->new($google_map_geo_url);
    $geo_uri->query_form_hash(
        q      => encode('utf-8', $point->{addr}),
        output => 'json',
        key    => $google_map_api_key,
    );
    my $ua      = LWP::UserAgent->new;
    my $resp    = $ua->get( $geo_uri );
    my $geo_res = JSON->new->utf8(0)->decode($resp->content);
    # - Google Geocode API が１日利用上限に達したらスクリプト終了にする
    my $status  = $geo_res->{Status}->{code};
    die "Limit of Google Geocode API" if($status==620);
    my $lng = $geo_res->{Placemark}[0]->{Point}->{coordinates}[0];
    my $lat = $geo_res->{Placemark}[0]->{Point}->{coordinates}[1];
    if (!$lat or !$lng) {
        $lat = '';
        $lng = '';
    }
    my $loc = ();
    $point->{lng} = $lng;
    $point->{lat} = $lat;
    #$point->{loc} = $loc;

print $point->{addr};
print Dumper($geo_res);
exit;
    ## ------------
    ## Add "loc" field
    ## ------------
    $point->{loc} = { lng => $point->{lng}, lat => $point->{lat} };
    delete $point->{lat};
    delete $point->{lng};
    $col->save($point); 
}

