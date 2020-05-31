create database if not exists yu_wp_data;


/*
*
* ssl_status have either of 3 values 
 0 Cert not requested yet
 1 Cert requested
 2 Cert Issued
 3 Cert Couldn't Issued
*/
/**
 Site Status have these states
 0 Site is not provisioned yet
 1 Site is provisioned successfully
 2 Couldn't Provision site due to error
**/
create table if not exists yu_wp_data.orders(oid int,nid varchar(50),site_status tinyint default 0,ssl_status tinyint default 0,otype char(3),domain varchar(50) ,domains varchar(1000));
