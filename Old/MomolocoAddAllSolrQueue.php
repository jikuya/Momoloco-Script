<?php
## ===========================================
## Define
## ===========================================
$mongo_host  = 'localhost';
$mongo_port  = 27017;
$mongo_db1   = 'momoloco';
$mongo_col1  = 'point';
$mongo_db2   = 'momoloco_queue';
$mongo_col2  = 'point_queue';

## ===========================================
## Execute
## ===========================================
## ------------
## Get All Point Info From MongoDB
## ------------
$con = new Mongo("mongodb://{$mongo_host}");
$db1  = $con->selectDB($mongo_db1);
$col1 = $db1->$mongo_col1;
$cursor = $col1->find()->sort(array("_id" => 1));
$db2  = $con->selectDB($mongo_db2);
$col2 = $db2->$mongo_col2;
foreach ($cursor as $obj) {
    if(array_key_exists('lat', $obj)) continue;
    $obj = array('oid' => $obj['_id'], 'status' => 'insert');
    $col2->insert($obj);
}
