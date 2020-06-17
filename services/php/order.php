<?php

define("WP_USE_THEMES", false);
require_once __DIR__ . "/wp-blog-header.php";
require_once __DIR__ . '/include.php';
check_for_fallback();
$user = wp_get_current_user();

wp_enqueue_style('pure-css', './assets/pure-min.css');
wp_enqueue_style('custom-style', "./assets/style.css");
get_header();
$oid = $_GET["id"];
$uid = $user->ID;

$order = null;
if (false === ($orders = get_transient("orders:" . $uid))) {
    //Orders not found

    $c = get_wc_client();
    $to = $c->get("orders/" . esc_js($oid));
    $order = ["id" => $to["id"], "product_name" => $to["line_items"][0]["name"]];
} else {
    //Found in transient
    foreach ($orders as $to) {
        if ($to["id"] == $oid) {
            $order = $to;
            break;
        }
    }
}
$ssl = wp_remote_get(YU_API_SERVER . "/req/ssl", ["id" => $oid]);
$site = wp_remote_get(YU_API_SERVER . "/req/site", ["id" => $oid]);
$ssl_status = null;
$site_body = null;

if (wp_remote_retrieve_response_code($ssl) === 200) {
    $ssl_status = wp_remote_retrieve_body($ssl)["status"];
} else {
    //Fallback
}
if (wp_remote_retrieve_response_code($site) === 200) {
    $site_body = wp_remote_retrieve_body($site);
} else {
    //Fallback
}

//WP Stuff
get_header();
wp_enqueue_style("pure-css", "./assets/pure/style.css");

?>
<div>
    <? require __DIR__."/menu.php" ?>
    <!-- Menu  --->

    <h1>Order -
        <? echo $order["id"]; ?>
    </h1>
    <div>
        <h2>Plan - <b>
                <? echo $order["product_name"] ?></b></h2>

        <div>
            <!-- Site Area Start -->

            <h3>Site Status</h3>
            <br />
            <div>
                <table>
                    <tr>
                        <td>Primary Domain</td>
                        <td>
                            <?  echo $site_body["domain"] ?>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            Temorary Domain
                        </td>
                        <td>
                            <? echo $site_body["tempDomain"] ?>
                        </td>
                    </tr>
                    <? foreach($site_body["domains"]as $domain) : ?>
                    <tr>
                        <td>Secondary Domain</td>
                        <td>
                            <? echo $domain ?>
                        </td>
                    </tr>
                    <? endforeach; ?>
                    <tr>
                        <td>Site IP(s)</td>
                        <td>
                            <? foreach($site_body["ips"] as $ip): ?>
                            <a href="#">
                                <? echo $ip;?></a>,&nbsp;
                            <? endforeach; ?>
                        </td>
                    </tr>

                </table>
            </div>
            <?
                $btnc=null;
                $btntext=null;
            switch($site_body["status"]) {
                case "0":
                    $btnc="secondary";
                    $btntext="It seeems, Your site is not online yet, in Provisioning Queue, It may take few seconds to get it online.";
                break;
                case "1":
                    $btn="success";
                    $btntext="Your Site is online !! ";
                break;
                case "2":
                    $btn="error";
                    $btntext="We couldn't provision your site, Please contact us";   
                break;

           }
           $btnc="pure-button button-".$btnc;
           ?>

            <button class='<?echo $btnc ?>'>
                <?  echo $btntext?></button>
            <? if($site_body["status"]==1) :?>
            <br />
            Customize your site at <a href='<? echo $site_body["tempDomain"] ?>'>
                <? echo $site_body["tempDomain"] ?>
            </a>
            <? endif; ?>
            <!-- Site Area  End-->
        </div>
        <div>
            <!-- SSL Area Start -->
            <h3>SSL Status</h3>
            <? 
                        switch($ssl_status){
                                case "0":
                                $btnc="x";
                                $btntext="Request Free SSL Now";
                                break;
                                case "1":
                                    $btnc="secondary";
                                    $btntext=YU_SSL_STATUES["1"];
                                break;
                                case "2":
                                    $btnc="success";
                                    $btntext=YU_SSL_STATUES["2"];
                                break;
                                case "3":
                                    $btnc="error";
                                    $btntext=YU_SSL_STATUES["3"];
                                break;
                        }
                        $btnc="pure-button button-".$btnc;
                ?>
            <button class="<? echo $btnc; ?>" <? echo ($ssl_status==0) ? "id='provision-ssl-btn'" :""; ?> >
                <? echo $btntext ?>
            </button>
            <br />
            <? if($ssl_status==0): ?>
            <h3><u>Before Provisioning SSL Certificate Please Make sure below points</u></h3>
            <ul>
                <li>
                    SSL Certificating is an automatic process.
                </li>
                <li>
                    All the domains/subdomains of your site should point to either of these IP(s).
                    <? foreach($site_body["ips"] as $ip): ?>
                    <a href="#">
                        <? echo $ip; ?></a><br />
                    <? endforeach;?>
                </li>
                <li>
                    Please ensure that you have <b>A</b> DNS Record entry for each of your domains,
                    e.g. if you have domain/sub domain <a href='#'>sub1.mydomain.tld</a>, <a href='#'>sub1.mydomain.tld</a>
                    &nbsp; then all of these domain must point to above listed ips.

                </li>
                <li>Contact Us or your DNS Registrar for further assitance.</li>
            </ul>
            <? endif ?>
            <!-- SSL Area End -->
        </div>
    </div>
</div>
<?php
get_footer();
?>