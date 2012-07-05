<?php

require('config.php');

$q = mysql_query('select * from cities where (population > 200000 AND (country_code = "us" OR country_code = "gb" OR country_code = "ca" OR country_code = "jp" OR country_code = "de")) OR population > 3000000 order by ascii_name asc');

while ($city = mysql_fetch_assoc($q)) {
//    echo 'this.source.push(new City(' . $city['id'] . ', "' . $city['name'] . '", "' . $city['state_region'] . '", "' . $city['country_code'] . '"));<br>';

    $name = $city['name'];
//    if($city['country_code'] == 'us') $name .= ", $city[state_region]";
    
    $url_name = str_replace(' ', '', $city['ascii_name']);
    $creator_user_id = 0;
    echo "('$name', '$url_name', $city[id], 0, NOW(), 1), <br>";
}

?>