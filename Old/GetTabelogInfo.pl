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

my $url_f    = 'http://r.tabelog.com/CC';
my $url_pref = '';
my $url_area = '';
my $url_m    = '0/0/COND-0-0-2-0-0-0-0-0/D-rt';
my $url_page = 1;
my $url_b    = '?LstSmoking=0&LstReserve=0';

my $area_code_file_path = 'cafe_info_from_tabelog.csv';

my $google_map_geo_url = 'http://maps.google.com/maps/geo';
my $google_map_api_key = 'ABQIAAAAY7WrwEvnj5MzQ53HSduoZxTGUeZekLo8tKJ4I2JH-Ar4EQD8QxSmLbV2pmQWFEsJ55l5Z32uNVcIIg';

## ===========================================
## Setting Scraper
## ===========================================
my $scraper1 = scraper {
    process "div.page-move" => "next" => 'TEXT';
    process "/html/body/div[9]/div/ul/li/div/div/strong/a" => "list[]" => '@href';
};
$scraper1->user_agent(
    LWP::UserAgent->new(agent => "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)")
);

my $scraper2 = scraper {
    process 'p.mname strong', 'name' => 'TEXT';
    process 'span[property="v:category"]', 'genre[]' => 'TEXT';
    process 'strong[property="v:tel"]', 'tel' => 'TEXT';
    process 'p[rel="v:addr"]', 'addr' => 'TEXT';
    process "table.rst-data tbody tr" , 'extra[]' =>'HTML';
};
$scraper2->user_agent(
    LWP::UserAgent->new(agent => "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)")
);
## ===========================================
## Execute
## ===========================================
#my $i = 0;
open(IN, $area_code_file_path);
while ( my $line = <IN>) {
    ## ------------
    ## make url
    ## ------------
    my @list = split(/,/, $line);
    $url_pref = @list[0] if (@list[0]);
    $url_area = @list[1] if (@list[1]);
    next if (!$url_pref or !$url_area);
    ## ------------
    ## GET NEXT PAGE INFO
    ## ------------
    my $end = 1;
    my $url_page = 1;
    while ($end==1) {
        ## ------------
        ## make url
        ## ------------
        my $url = "$url_f/$url_pref/$url_area/$url_m/$url_page/$url_b";
        my $res1 = $scraper1->scrape(URI->new($url));
        ## ------------
        ## STEP insert MongoDB
        ## ------------
        for my $store_url (@{$res1->{list}}){
            my $post = ();
            my $res2;
            eval { $res2 = $scraper2->scrape(URI->new($store_url)) };
            next if($@);
            ## ------------
            ## カテゴリの先頭がカフェと無縁そうなものはSKIP
            ## ------------
            my $skip = 1;
            $skip = 0 if($res2->{genre}[0]=~ /カフェ/);
            $skip = 0 if($res2->{genre}[0]=~ /コーヒー専門店/);
            $skip = 0 if($res2->{genre}[0]=~ /紅茶専門店/);
            $skip = 0 if($res2->{genre}[0]=~ /パン/);
            $skip = 0 if($res2->{genre}[0]=~ /ケーキ/);
            $skip = 0 if($res2->{genre}[0]=~ /カフェ・喫茶（その他）/);
            $skip = 0 if($res2->{genre}[0]=~ /喫茶店/);
            $skip = 0 if($res2->{genre}[0]=~ /チョコレート/);
            $skip = 0 if($res2->{genre}[0]=~ /洋菓子（その他）/);
            $skip = 0 if($res2->{genre}[0]=~ /フルーツパーラー/);
            $skip = 0 if($res2->{genre}[0]=~ /甘味処/);
            $skip = 0 if($res2->{genre}[0]=~ /パフェ/);
            $skip = 0 if($res2->{genre}[0]=~ /アイスクリーム/);
            $skip = 0 if($res2->{genre}[0]=~ /クレープ/);
            $skip = 0 if($res2->{genre}[0]=~ /ドーナツ/);
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
            ## get latitude & longitude
            ## ------------
            my $geo_uri = URI->new($google_map_geo_url);
            $geo_uri->query_form_hash(
                q      => encode('utf-8', $post->{addr}),
                output => 'json',
                key    => $google_map_api_key,
            );
            my $ua      = LWP::UserAgent->new;
            my $resp    = $ua->get( $geo_uri );
            my $geo_res = JSON->new->utf8(0)->decode($resp->content);
            # - Google Geocode API が１日利用上限に達したらスクリプト終了にする
            my $status  = $geo_res->{Status}->{code};
            die "Limit of Google Geocode API" if($status==620);
            $post->{lng} = $geo_res->{Placemark}[0]->{Point}->{coordinates}[0];
            $post->{lat} = $geo_res->{Placemark}[0]->{Point}->{coordinates}[1];
            if (!$post->{lat} or !$post->{lng}) {
                $post->{lng} = '';
                $post->{lat} = '';
            }
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
        if($res1->{next} !~ /次へ/){
            $end = 0;
        } else {
            $url_page++;
        }
#$i++;
#exit if ($i == 0);
    }
}

