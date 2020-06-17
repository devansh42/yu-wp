document.querySelector("#provison-ssl-btn").addEventListener("click", (ele, event) => {
    let order = window.order; // Set by php backend
    let apiEndpoint = window.apiEndpoint;
    fetch([apiEndpoint, "req", "ssl"].join("/").concat("?id=" + order.id))
        .then(r => {
            if (r.status == 200) {
                //SSL Requested
                alert("SSL Certificate Requested");
                ele.innerHTML = "Your SSL Certificate is in process of provisioning";
                ele.classlist.add("button-secondary");
            } else {
                alert("Couldn't Request SSL, Please Try later or Contact Us if problem persists");
            }
        });
})