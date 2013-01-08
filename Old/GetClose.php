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
$fp = fopen('closed.cvs', 'w');
foreach ($cursor as $obj) {
    $data = $obj['closed']."\n";
    fwrite($fp,  $data);
}
fclose($fp);
