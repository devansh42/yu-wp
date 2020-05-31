"""
This module defines api endpoints
"""
import logging
import os.path
from mysql.connector import errors
from flask import Flask, request
from .secrets import LOGGIN_DIR
from .orders import check_site_status, check_ssl_status, process_ssl, process_order
app = Flask(__name__)

logging.basicConfig(filename=os.path.join(
    LOGGIN_DIR, "backend.log"), level=logging.DEBUG)


@app.route("/check/ssl", methods=["GET"])
def check_ssl():
    args = request.args
    id = args.get("id")  # Order Id
    status = check_ssl_status({"id": id})
    return {"status": status}


@app.route("/check/site", methods=["GET"])
def check_site():
    args = request.args
    id = args.get("id")
    status = check_site_status({"id": id})
    return {"status": status}


@app.route("/req/ssl", methods=["GET"])
def req_ssl():
    args = request.args
    id = args.get("id")  # Order Id
    res = ("ok", 200)

    try:
        process_ssl({"id": id})
    except errors.Error as e:
        res = ("Internal server error", 500)
        logging.error(e.msg)
    return res


@app.route("/orders/new", methods=["POST"])
def order_new():
    order = request.form
    res = ("ok", 200)
    try:
        (s, t) = process_order(order)
        res = ({"temp_domain": t, "site_domain": s}, 200)
    except errors.Error as e:
        logging.error(e.msg)
        res = (
            "Some internal server error, Please try later or contact us if problem persists", 500)
    return res
