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
    my %loc = ();
    $point->{sts} = 0;
    $point->{sts_timestamp} = time();
    $col->save($point);
}

