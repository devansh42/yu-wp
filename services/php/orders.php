<?php
define("WP_USE_THEMES", false);
require_once __DIR__ . "/wp-blog-header.php";
require_once __DIR__ . '/include.php';
check_for_fallback();

$uid = wp_get_current_user()->ID;

if (false === ($orders = get_transient("orders:" . $uid))) {
    $c = get_wc_client();
    $orders = $c->get("orders", ["customer_id" => $uid]);
    $to = [];
    foreach ($orders as $order) {
        array_push($to, ["id" => $order["id"], "product_name" => $order["line_items"][0]["name"]]);
    }
    $order = $to;
    set_transient("orders:" . $uid, $orders);
}


//Saving this stuff in transient

//WP Stuff
get_header();
wp_enqueue_style("pure-css", "./assets/pure-min.css");

?>
<div>
    <? require __DIR__."/menu.php" ?>
    <!-- Menu  --->
    <h1>Your Order(s)</h1>
    <div>
        <table class="pure-table">
            <thead>
                <tr>
                    <td>#</td>
                    <td>Order Id</td>
                    <td>Plan/Item</td>
                </tr>
            </thead>
            <tbody>
                <?php $ocount = 0;
                foreach ($orders as $order) : ?>
                    <tr>
                        <td>
                            <?php echo ++$ocount; ?>
                        </td>
                        <td>
                            <a href='ordes.php?id=<?php echo ($order["id"]) ?>'>
                                <?php echo esc_js($order["id"]) ?>
                            </a>
                        </td>
                        <td>
                            <?php echo $order["product_name"]
                            /** Product name */
                            ?>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>

        </table>
        <h3>
            <? echo $ocount ?> Order(s) found</h3>
    </div>
</div>
<?php
get_footer();
?>