<?php
## ===========================================
## Define
## ===========================================
$mongo_host = 'localhost';
$mongo_port = 27017;
$mongo_db   = 'momoloco';
$mongo_col  = 'point';

## ===========================================
## Execute
## ===========================================
## ------------
## Get All Point Info From MongoDB
## ------------
$con = new Mongo("mongodb://{$mongo_host}");
$db  = $con->selectDB($mongo_db);
$col = $db->$mongo_col;
$cursor = $col->find();
foreach ($cursor as $obj) {
    if(array_key_exists('lat', $obj)) continue;
    $latlng = "{$obj['loc']['lat']},{$obj['loc']['lng']}";
    $obj['latlng'] = $latlng;
    $col->save($obj);
}
