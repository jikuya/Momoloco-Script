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
my $mongo_col  = 'skylarks';

my $list_url_base = 'http://sp.chizumaru.com/dbh/skylark/list.aspx?account=skylark&accmd=0&arg=&c1=10016%2C170001%2C20001%2C370002&c2=0&c3=&c4=&c5=&c6=&c7=&c8=&c9=&c10=&c11=&c12=&c13=&c14=&c15=&c16=&c17=&c18=&c19=&c20=&c21=&c22=&c23=&c24=&c25=&c26=&c27=&c28=&c29=&c30=&mode=11&key=&pg=';
my $list_url_pg   = '';

my $shop_url_base = 'http://sp.chizumaru.com/dbh/skylark/detailmap.aspx?account=skylark&accmd=0&arg=&c1=10016%2C170001%2C20001%2C370002&c2=0&c3=&c4=&c5=&c6=&c7=&c8=&c9=&c10=&c11=&c12=&c13=&c14=&c15=&c16=&c17=&c18=&c19=&c20=&c21=&c22=&c23=&c24=&c25=&c26=&c27=&c28=&c29=&c30=&mode=11&key=&pg=1&adr=&orgpg=1&comp=&bid=';
my $shop_url_bid  = '';

my $debug = 0;

## ===========================================
## Setting Scraper
## ===========================================
## tbodyは認識されないので、XPathから外す
my $scraper1 = scraper {
    process 'table.map_list > tr > td > a', 'shop_url_list[]' => '@href';
    result 'shop_url_list';
};
$scraper1->user_agent(
    LWP::UserAgent->new(agent => "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)")
);

my $scraper2 = scraper {
    process '/html/body/center/table/tr[2]/td/div/table[2]/tr/td/table/tr/td/strong', 'name' => 'TEXT';
    #process '/html/body/center/table/tr[2]/td/div/table[2]/tr/td/table/tr[2]/td/span', 'addr_tel' => 'TEXT';
    #process '/html/body/center/table/tr[2]/td/div/table[2]/tr/td/table/tr/td[3]/span', 'addr_tel' => 'TEXT';
    process 'table.map_list > tr > td > span.f14', 'addr_tel[]' => 'TEXT';
    process '/html/body/center/table/tr[2]/td/div/table[2]/tr/td/table/tr/td[2]/table/tr/td[5]/span', 'weekday' => 'TEXT';
    process '/html/body/center/table/tr[2]/td/div/table[2]/tr/td/table/tr/td[2]/table/tr[2]/td[5]/span', 'saturday' => 'TEXT';
    process '/html/body/center/table/tr[2]/td/div/table[2]/tr/td/table/tr/td[2]/table/tr[3]/td[5]/span', 'holiday' => 'TEXT';
};
$scraper2->user_agent(
    LWP::UserAgent->new(agent => "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)")
);

## ===========================================
## Execute
## ===========================================
my $i = 19;
while ( $i <= 117 ) {
    ## ------------
    ## Make url
    ## ------------
    $list_url_pg = $i;
    my $list_url = $list_url_base . $list_url_pg;
    ## ------------
    ## Get shop list info 
    ## ------------
    my $res1 = $scraper1->scrape(URI->new($list_url));
    ## ------------
    ## Get shop info 
    ## ------------
    for my $shop_js_url (@$res1) {
        $shop_js_url =~ /^javascript:PageLink\('([0-9]+)',/;
        $shop_url_bid = $1;
        my $shop_url = $shop_url_base . $shop_url_bid;
        my $res2 = $scraper2->scrape(URI->new($shop_url));
        my $post = ();
        my $addr_tel = $res2->{addr_tel}[1];
        my @addr_tel = split(/\s/, $addr_tel);
        $post->{name}       = $res2->{name};
        $post->{addr}       = @addr_tel[2];
        $post->{tel}        = @addr_tel[5];
        $post->{weekday}    = $res2->{weekday};
        $post->{saturday}   = $res2->{saturday};
        $post->{holiday}    = $res2->{holiday};
        $post->{remarks}    = "";
        $post->{str_code}   = $shop_url_bid;
        $post->{str_url}    = $shop_url;
        ## ------------
        ## If NotFound shop info
        ## ------------
        if (!defined($res2->{name})) {
            sleep 1;
            next;
        }
        ## ------------
        ## Debug
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
    }
    ## ------------
    ## Increment
    ## ------------
    $i++;
}
