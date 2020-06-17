<?php
require_once __DIR__ . 'vendor/autoload.php';

use Automattic\WooCommerce\Client;

function get_wc_client()
{
    return new Client("wsws", "wsw", "ws", [
        'version' => 'wc/v3'
    ]);
}

//Defining script wide constants
define("YU_API_SERVER", $_ENV["YU_API_SERVER"]);
define("YU_WEBSITE", $_ENV["YU_WEBSITE"]);
define("YU_SSL_STATUES", [
    "0" => "SSL not Provisioned yet",
    "1" => "SSL has been provisioning ",
    "2" => "SSL has been successfully issued",
    "3" => "Couldn't Provision your SSL Certificate"

]);
define("YU_SITE_STATUS", [
    "0" => "Site not provisioned yet",
    "1" => "Site is online",
    "2" => "Couldn't Provision Your Site"
]);


function check_for_fallback()
{

require_once './wp-blog-header.php';

    if (false === wp_get_current_user()) {
        wp_redirect(YU_WEBSITE);
    }
}
