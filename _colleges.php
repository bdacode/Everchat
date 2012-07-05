<?php

require('config.php');

$q = mysql_query('select * from colleges where size > 3000 order by name asc');

while ($city = mysql_fetch_assoc($q)) {
    echo 'this.push(new College(' . $city['id'] . ', "' . $city['name'] . '"));<br>';


}

?>