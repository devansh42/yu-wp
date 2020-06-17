<?php

define("WP_USE_THEMES", false);
require __DIR__ . "/wp-blog-header.php";
wp_enqueue_style('pure-css', './assets/pure-min.css');
get_header();

?>
<div>
    <? require __DIR__."/menu.php";?>
    <div>
        <center>
            <h1>
                Hey Buddy! You need to login to see this page
            </h1>
        </center>
    </div>
</div>
<?php
get_footer();
