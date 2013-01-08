<?php
## ===========================================
## Define
## ===========================================
$mongo_host = 'localhost';
$mongo_port = 27017;
$mongo_db   = 'momoloco_queue';
$mongo_col  = 'point_queue';

## ===========================================
## Execute
## ===========================================
## ------------
## Get All Point Info From MongoDB
## ------------
$con = new Mongo("mongodb://{$mongo_host}");
$db  = $con->selectDB($mongo_db);
$col = $db->$mongo_col;
$obj = array('uid' => '4e8ab94871acaeba24000001', 'status' => 0);
$col->save($obj);
