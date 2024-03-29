package main

import (
	"bufio"
	"context"
	"crypto/md5"
	"database/sql"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"os"
	"path"
	"strings"
	"time"

	"github.com/digitalocean/godo"
	"github.com/go-redis/redis"
	_ "github.com/go-sql-driver/mysql"
	"github.com/labstack/echo"
	"github.com/pkg/errors"
)

const (
	ORDER_SITE       = "site"
	ORDER_SSL        = "ssl"
	RESPONSECH       = "res-yu-wp"
	BEGINNER   Plan  = 0
	ADVANCE    Plan  = 1
	SSL        otype = 1
	SITE       otype = 0
	LOGGIN_DIR       = "/var/log/backend"
)

var (
	DOMAINSUFFIX = os.Getenv("DOMAINSUFFIX")
	DOTOKEN      = os.Getenv("DOTOKEN")
	MYSQL_HOST   = os.Getenv("MYSQL_HOST")
	REDIS_HOST   = os.Getenv("REDIS_HOST")
	MYSQL_PASSWD = os.Getenv("MYSQL_PASSWD")
	NODESFILE    = os.Getenv("NODESFILE")

	choosenNode    = 0 //Initially choosen node
	chOrderProcess = make(chan orderMsg, 10)
)

type Plan uint8
type node struct {
	Id, Hostname, Domain string
}

type orderMsg struct {
	node  *node
	order *order
}

type order struct {
	Id string `json:"id"`

	Domain  string `json:"domain"`
	Domains string `json:"domains"`

	TempDomain string            `json:"temp_domain"`
	Plan       Plan              `json:"plan"`
	Wp         map[string]string `json:"wp"`
	Type       otype             `json:"type"`
}
type otype uint8

type nginxconf struct {
	BindAddr, ServerNames, TempName, OID string
}
type responseMsg struct {
	Id     string `json:"id"`
	Type   otype  `json:"type"`
	Status int    `json:"status"`
	Msg    string `json:"msg"`
}

func getDB() (*sql.DB, error) {
	return sql.Open("mysql", fmt.Sprint("root:", MYSQL_PASSWD, "@tcp(", MYSQL_HOST, ":3306)/", "yu_wp_data"))

}

func getRedis() *redis.Client {
	return redis.NewClient(&redis.Options{
		Addr: fmt.Sprint(REDIS_HOST, ":", 6379)})

}
func createUserAndDB(tx *sql.Tx, username, passwd, dbname string) error {
	sql := "create user '%s'@ identified by '%s'"

	_, err := tx.Exec(fmt.Sprintf(sql, username, passwd))
	if err != nil {
		return err
	}

	_, err = tx.Exec(fmt.Sprintf("create database %s", dbname))
	if err != nil {
		return err
	}
	_, err = tx.Exec(fmt.Sprintf("grant all PRIVILEGES on %s.* to %s@", dbname, username))
	if err != nil {
		return err
	}
	return nil
}

func processSiteOrder(o *order) (string, error) {
	db, err := getDB()

	if err != nil {
		return "", err
	}
	defer db.Close()
	//Creating db user and all
	tx, _ := db.Begin()
	username := fmt.Sprint("yu_", o.Id)
	passwd := getRandomPasswd(o)

	dbname := fmt.Sprint("yu_wp_user_data_", o.Id)
	err = createUserAndDB(tx, username, passwd, dbname)
	if err != nil {
		tx.Rollback()
		return "", err
	}
	node := getNextNode()
	o.Wp = map[string]string{
		"WORDPRESS_DB_USER":          username,
		"WORDPRESS_DB_PASSWORD":      passwd,
		"WORDPRESS_DB_NAME":          dbname,
		"WORDPRESS_DB_HOST":          MYSQL_HOST,
		"WORDPRESS_AUTH_KEY":         getRandomString(o, 1),
		"WORDPRESS_SECURE_AUTH_KEY":  getRandomString(o, 2),
		"WORDPRESS_LOGGED_IN_KEY":    getRandomString(o, 3),
		"WORDPRESS_NONCE_KEY":        getRandomString(o, 4),
		"WORDPRESS_AUTH_SALT":        getRandomString(o, 5),
		"WORDPRESS_SECURE_AUTH_SALT": getRandomString(o, 6),
		"WORDPRESS_LOGGED_IN_SALT":   getRandomString(o, 6),
		"WORDPRESS_NONCE_SALT":       getRandomString(o, 7),
		"OID":                        o.Id,
		"NODEID":                     node.Hostname}
	o.TempDomain = getTempDomain(o, node.Domain)
	err = setTempDomain(node.Domain, o)
	if err != nil {
		tx.Rollback()
		return "", errors.Wrap(err, "Couldn't set temporaray domain name")
	}
	stmt, err := tx.Prepare("insert into orders(oid,nid,temp_domain,otype,domain,domains)values(?,?,?,?,?,?)")
	if err != nil {
		tx.Rollback()
		return "", err
	}
	_, err = stmt.Exec(o.Id, node.Hostname, o.TempDomain, o.Type, o.Domain, o.Domains)
	if err != nil {
		tx.Rollback()
		return "", err
	}
	chOrderProcess <- orderMsg{&node, o} //Sending for order processing
	err = tx.Commit()
	if err != nil {
		tx.Rollback()
		return "", errors.Wrapf(err, "Couldn't commit tx: order id  %s", o.Id)
	}

	return node.Domain, nil
}

func processSSLOrder(o *order) error {
	db, err := getDB()
	if err != nil {
		return err
	}
	defer db.Close()
	stmt, err := db.Prepare("select domain,domains,temp_domain,nid from orders where oid=? limit 1")
	if err != nil {
		return err
	}
	defer stmt.Close()
	rs, err := stmt.Query(o.Id)
	if err != nil {
		return err
	}
	defer rs.Close()
	for rs.Next() {
		var h string
		rs.Scan(&o.Domain, &o.Domains, &o.TempDomain, &h)
		o.Type = SSL
		chOrderProcess <- orderMsg{&node{Hostname: h}, o} //Sending order for processing
	}
	return nil
}

func checkStatus(o *order, t otype) (int, string, string, string, error) {
	var tempDomain, domain, domains string

	db, err := getDB()
	if err != nil {
		return 500, "", "", "", err
	}
	defer db.Close()

	sql := "select site_status,temp_domain,domains,domain from orders where oid=? limit 1"
	if t == SSL {
		sql = "select ssl_status from orders where oid=? limit 1"
	}
	stmt, err := db.Prepare(sql)
	if err != nil {
		return 500, "", "", "", err
	}
	defer stmt.Close()
	r, err := stmt.Query(o.Id)
	if err != nil {
		return 500, "", "", "", err
	}
	var status int
	for r.Next() {
		if t == SITE {
			r.Scan(&status, &tempDomain, &domains, &domain)
		} else {
			r.Scan(&status)

		}
		break
	}
	return status, tempDomain, domains, domain, nil

}
func checkSSLStatus(o *order) (int, error) {
	s, _, _, _, err := checkStatus(o, SSL)
	return s, err
}
func checkSiteStatus(o *order) (int, string, string, string, error) {
	return checkStatus(o, SITE)

}

func getRandomString(o *order, round int) string {
	n := md5.New()
	b := n.Sum([]byte(fmt.Sprintf(o.Id, time.Now().UnixNano())))
	for i := 0; i < round; i++ {
		b = n.Sum(b)
	}
	x := base64.StdEncoding
	return x.EncodeToString(b)
}

func getRandomPasswd(o *order) string {
	n := md5.New()
	return hex.EncodeToString(n.Sum([]byte(fmt.Sprintf(o.Id, time.Now().UnixNano()))))
}

func getTempDomain(o *order, dom string) string {
	return strings.Join([]string{fmt.Sprint("o", o.Id), dom}, ".")
}

func setTempDomain(dom string, o *order) error {
	c := godo.NewFromToken(DOTOKEN)
	x := new(godo.DomainRecordEditRequest)
	x.Type = "CNAME"
	x.Name = strings.Join(strings.Split(o.TempDomain, ".")[:2], ".")
	x.Data = fmt.Sprint(dom, ".") // Appending dot for cname record
	_, _, err := c.Domains.CreateRecord(context.Background(), DOMAINSUFFIX, x)
	return err
}

func orderSender(r *redis.Client) {
	for v := range chOrderProcess {
		b, _ := json.Marshal(v.order)
		x := r.Publish(context.Background(), fmt.Sprintf("n%s-yu-wp", v.node.Hostname), string(b))
		err := x.Err()
		if err != nil {
			log.Print(errors.Wrapf(err, "Couldn't send order for processing"), *v.order)
			continue
		}
	}
}

func responseConsumer(ch <-chan *redis.Message) {
	for v := range ch {
		s := v.Payload
		r := new(responseMsg)
		json.Unmarshal([]byte(s), r)
		go consumeRespMsg(r)
	}
}

func consumeRespMsg(r *responseMsg) {
	er := func() error {
		db, err := getDB()
		if err != nil {
			return err
		}
		defer db.Close()
		tx, _ := db.Begin()
		var sql string
		if r.Type == SSL {
			sql = "update orders set ssl_status = ? where oid = ? limit 1"
		} else {
			sql = "update orders set site_status = ? where oid = ? limit 1"
		}
		stmt, err := tx.Prepare(sql)
		if err != nil {
			return err
		}
		_, err = stmt.Exec(r.Status, r.Id)
		if err != nil {
			return err
		}
		err = tx.Commit()
		if err != nil {
			tx.Rollback()
			return err
		}
		return nil
	}()
	if er != nil {
		log.Print(errors.Wrap(er, "Coudn't consume response message"), *r)
	}
}

func getNodeList() []node {

	b, _ := os.Open(NODESFILE)
	var ns []node
	s := bufio.NewScanner(b)
	defer b.Close()
	for s.Scan() {
		line := s.Text()
		line = strings.TrimSpace(line)
		lp := strings.Split(line, " ")
		ns = append(ns, node{lp[0], lp[1], lp[2]})
	}

	return ns
}

func getNextNode() node {
	ns := getNodeList()
	if choosenNode >= len(ns) {
		choosenNode = 0
	}
	n := ns[choosenNode]
	choosenNode++
	return n
}

/*
*
* ssl_status have either of 3 values
 0 Cert not requested yet
 1 Cert requested
 2 Cert Issued
 3 Cert Couldn't Issued
*/
func apicheckSSL(e echo.Context) error {
	o := new(order)
	o.Id = e.QueryParam("id")
	status, err := checkSSLStatus(o)
	if err != nil {
		log.Print("/check/ssl\t", err, *o)
		return e.String(500, "Internal server error")
	}
	return e.JSON(200, map[string]interface{}{"status": status})
}

/**
 Site Status have these states
 0 Site is not provisioned yet
 1 Site is provisioned successfully
 2 Couldn't Provision site due to error
**/
func apicheckSite(e echo.Context) error {
	o := new(order)
	o.Id = e.QueryParam("id")
	status, tempdomain, domains, domain, err := checkSiteStatus(o)
	ips, err := net.LookupIP(tempdomain)
	if err != nil {
		err = errors.Wrap(err, "Couldn't lookup ip address")
	}
	if err != nil {
		log.Print("/check/site\t", err, *o)
		return e.String(500, "Internal server error")
	}

	return e.JSON(200,
		map[string]interface{}{"status": status,
			"ips":        convertIP2String(ips),
			"tempDomain": tempdomain, "domain": domain, "domains": strings.Split(domains, ",")})

}
func convertIP2String(a []net.IP) []string {
	var x []string
	for _, v := range a {
		x = append(x, v.String())
	}
	return x
}
func apireqSSL(e echo.Context) error {
	o := new(order)
	o.Id = e.QueryParam("id")
	err := processSSLOrder(o)
	if err != nil {
		log.Print("/req/ssl\t", err, *o)
		return e.String(500, "Internal server error")
	}
	return e.String(200, "ok")

}

func unbindRequestBody(o *order, e echo.Context) {
	m := make(map[string]interface{})
	if err := e.Bind(&m); err == nil {
		o.Id = fmt.Sprint(m["id"])

		items := m["line_items"].([]interface{})
		for _, v := range items {
			vx := v.(map[string]interface{})
			data := vx["meta_data"].([]interface{})
			for _, vv := range data {
				vvx := vv.(map[string]interface{})
				k := vvx["key"]
				vvv := vvx["value"]
				switch k {
				case "domain":
					o.Domain = fmt.Sprint(vvv)
				case "domains":
					o.Domains = fmt.Sprint(vvv)
				}
			}
			iid := fmt.Sprint(vx["id"])
			switch iid {
			case "0":
				o.Plan = BEGINNER
			case "1":
				o.Plan = ADVANCE
			}
			break //As There will only be on item
		}
	}
}

func apinewOrder(e echo.Context) error {
	o := new(order)
	unbindRequestBody(o, e)
	o.Type = SITE
	domain, err := processSiteOrder(o)
	if err != nil {
		log.Print("/order/new\t", err, *o)
		return e.String(500, "Internal server error")
	}
	return e.JSON(200, map[string]interface{}{
		"cname":       domain,
		"temp_domain": o.TempDomain})

}

func getApiServer() *echo.Echo {

	e := echo.New()
	e.GET("/check/ssl", apicheckSSL)
	e.GET("/check/site", apicheckSite)
	e.GET("/req/ssl", apireqSSL)
	e.POST("/orders/new", apinewOrder)

	return e
}

func main() {
	//Setting up logs
	f, err := os.OpenFile(path.Join(LOGGIN_DIR, "backend.log"), os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		panic(errors.Wrap(err, "Coudn't open logging file "))
	}
	defer f.Close()
	log.SetOutput(f)
	r := getRedis()
	ch := r.Subscribe(context.Background(), RESPONSECH)
	go responseConsumer(ch.Channel())
	go orderSender(r)
	a := getApiServer()
	a.Start(":80")
}
