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
my $mongo_col  = 'starbucks';

my $base_url   = 'http://www.starbucks.co.jp';
my $list_url_base = 'http://www.starbucks.co.jp/store/search/result_store.php?pref_code=';
my $list_url_pg   = '';
my $next_list_url = '';

my $shop_url_base = '';
my $shop_url_bid  = '';

## ===========================================
## Setting Scraper
## ===========================================
my $scraper1 = scraper {
    process "li.pagenationNext > a" => "next" => '@href';
    process 'td.storeName > a', 'store_url_list[]' => '@href';
};
$scraper1->user_agent(
    LWP::UserAgent->new(agent => "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)")
);
my $scraper2 = scraper {
    process "h1.heading1" => "name" => 'TEXT';
    process "/html/body/div/div[3]/div/div[3]/div/div/div/div[2]/table/tbody/tr[1]/td" => "1" => 'TEXT';
    process "/html/body/div/div[3]/div/div[3]/div/div/div/div[2]/table/tbody/tr[2]/td" => "2" => 'TEXT';
    process "/html/body/div/div[3]/div/div[3]/div/div/div/div[2]/table/tbody/tr[3]/td" => "3" => 'TEXT';
    process "/html/body/div/div[3]/div/div[3]/div/div/div/div[2]/table/tbody/tr[4]/td" => "4" => 'TEXT';
    process "/html/body/div/div[3]/div/div[3]/div/div/div/div[2]/table/tbody/tr[5]/td" => "5" => 'TEXT';
    process "/html/body/div/div[3]/div/div[3]/div/div/div/div[2]/table/tbody/tr[6]/td" => "6" => 'TEXT';
    process "/html/body/div/div[3]/div/div[3]/div/div/div/div[2]/table/tbody/tr[7]/td" => "7" => 'TEXT';
    process "/html/body/div/div[3]/div/div[3]/div/div/div/div[2]/table/tbody/tr[7]/th" => "extra" => 'TEXT';
};
$scraper2->user_agent(
    LWP::UserAgent->new(agent => "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)")
);
## ===========================================
## Execute
## ===========================================
my $i = 1;
while ( $i <= 47 ) {
    ## ------------
    ## make url
    ## ------------
    my $list_url = 'http://www.starbucks.co.jp/store/search/result_store.php?pref_code='.$i;
    my $res1 = $scraper1->scrape(URI->new($list_url));
    my $end = 1;
    for my $store_url (@{$res1->{stor_url_list}}){
        ## ------------
        ## make url
        ## ------------
        my $res2 = $scraper2->scrape(URI->new($store_url));
        ## ------------
        ## STEP insert MongoDB
        ## ------------
            my $post = ();
            if($res2->{extra}) {
                $post->{name}       = $res2->{name};
                $post->{addr}       = $res2->{2};
                $post->{tel}        = $res2->{3};
                $post->{weekday}    = $res2->{5};
                $post->{saturday}   = $res2->{2};
                $post->{holiday}    = $res2->{2};
                $post->{wifi}       = $res2->{6};
                $post->{str_url}    = $store_url;
            } else {
            }
            $skip = 0 if($res2->{genre}[0]=~ /スイーツ（その他）/);
            next if($skip == 1);
            ## ------------
            ## get store info
            ## ------------
            $post->{name}       = $res2->{name};
            $post->{genre}      = $res2->{genre};
            $post->{tel}        = $res2->{tel};
            $post->{addr}       = $res2->{addr};
            $post->{open_hours} = $res2->{extra}[5];
            $post->{closed}     = $res2->{extra}[6];
            $post->{tabelog_id} = 0;
            if ($store_url =~ m/\/(\d+)\/$/) { $post->{tabelog_id} = $1 };
            $post->{pref}       = $url_pref;
            $post->{area}       = $url_area;
            $post->{page}       = $url_page;

            ## ------------
            ## insert MongoDB
            ## ------------
            my $conn = MongoDB::Connection->new(host => "$mongo_host:$mongo_port");
            my $col  = $conn->$mongo_db->$mongo_col;
            my $id1  = $col->insert($post);
            ## ------------
            ## sleep
            ## ------------
            sleep 1;
        }
        ## ------------
        ## This step is end or continue ?
        ## ------------
        # - ページングがなくなったら同じエリアでの取得は終了する
        if(!$res1->{next}){
            $end = 0;
        } else {
            $next_list_url   = 'http://www.starbucks.co.jp'.$res1->{next};
        }
    }
    $i++;
}

