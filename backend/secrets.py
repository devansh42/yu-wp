from os import getenv
import mysql.connector as connector
import redis
WOO_URL = getenv("WOO_URL")
WOO_KEY = getenv("WOO_KEY")
WOO_SECRET = getenv("WOO_SECRET")
MYSQL_PASSWD = getenv("MYSQL_PASSWD")
MYSQL_HOST = getenv("MYSQL_HOST")
DEPLOYMENT_DIR = getenv("DEPLOYMENT_DIR")
REDIS_HOST = getenv("REDIS_HOST")
LOGGIN_DIR = getenv("LOG_DIR")


def get_default_mysql_conn():
    return connector.connect(host=MYSQL_HOST, user="root", passwd=MYSQL_PASSWD, database="yu_wp_data")


def get_default_redis_conn():
    return redis.Redis(host=REDIS_HOST)
