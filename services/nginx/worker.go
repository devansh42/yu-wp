package main

import (
	"context"
	"encoding/json"
	"fmt"
	"html/template"
	"io"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path"
	"strings"
	"sync"

	"github.com/docker/docker/api/types/filters"

	"github.com/docker/docker/api/types"
	"github.com/docker/docker/client"
	"github.com/go-redis/redis"
	"github.com/pkg/errors"
)

// Log files Used
// /var/log/wp
// /var/log/wp/ssl
// /var/log/wp/site

//Worker for our wp service
const (
	RESPONSECH       = "res-yu-wp"
	ORDER_SITE       = "site"
	ORDER_SSL        = "ssl"
	BEGINNER   Plan  = 0
	ADVANCE    Plan  = 1
	SSL        otype = 1
	SITE       otype = 0
)

var (
	REDIS_HOST                    = os.Getenv("REDIS_HOST")
	DNODEID                       = os.Getenv("DNODEID")
	DOCKER_REG                    = os.Getenv("DOCKER_REG")
	BACKUP_SITE_FILE              = os.Getenv("BACKUP_SITE_FILE")
	NGINX_CONF                    = os.Getenv("NGINX_CONF")
	EMAIL                         = os.Getenv("EMAIL")
	NODEID                        = os.Getenv("NODEID")
	nginxTemplate, dockerTemplate *template.Template
	respCh                        = make(chan respMsg, 10) //Buffered Channel
)

type Plan uint8

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
type ymlconf struct {
	OID, NODEID, DOCKER_REG string
}
type respMsg []byte

func getRedis() *redis.Client {
	return redis.NewClient(&redis.Options{
		Addr: fmt.Sprint(REDIS_HOST, ":", 6379)})

}
func consumeRedis(r *redis.Client, wg *sync.WaitGroup) {
	defer wg.Done()
	pb := r.Subscribe(context.Background(), fmt.Sprintf("n%s-yu-wp", NODEID))
	consumeReq(pb.Channel())

}

func responseConsumer(c *redis.Client, r <-chan respMsg, wg *sync.WaitGroup) {
	defer wg.Done()
	con := context.Background()
	for v := range r {
		c.Publish(con, RESPONSECH, v)
	}
}

func consumeReq(ch <-chan *redis.Message) {
	for x := range ch {
		o := new(order)
		json.Unmarshal([]byte(x.Payload), o)
		if o.Type == SSL {

			go handleNewSSLOrder(o)

		} else {
			go handleNewSiteOrder(o)

		}
	}
}

func enableBackup(o *order) {
	f, _ := os.OpenFile(BACKUP_SITE_FILE, os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0644)
	defer f.Close()
	f.Write([]byte(o.Id))
	f.Write([]byte("\n"))
}

func makeEnvFile(m map[string]string) []string {
	var ar []string
	for k, v := range m {
		ar = append(ar, fmt.Sprint(k, "=", v))
	}
	return ar
}

func handleNewSSLOrder(o *order) {
	var domains []string
	dd := strings.Split(o.Domains, " ")
	dd = append(dd, o.TempDomain)
	for _, v := range dd {
		if len(v) > 0 {
			domains = append(domains, "-d")
			domains = append(domains, v)
		}
	}

	//Preparing Reponse
	resp := new(responseMsg)
	resp.Id = o.Id
	resp.Type = o.Type
	resp.Status = 1

	b, _ := json.Marshal(resp)
	respCh <- b
	var cmdargs []string
	cmdargs = append(cmdargs, "--agree-tos", "-n", "-m", EMAIL, "--nginx")
	cmdargs = append(cmdargs, domains...)
	dep := exec.Command("certbot", cmdargs...)
	ef, _ := os.OpenFile("/var/log/wp/ssl/error.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	of, _ := os.OpenFile("/var/log/wp/ssl/log.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	defer ef.Close()
	defer of.Close()
	po, _ := dep.StdoutPipe()
	pe, _ := dep.StderrPipe()
	go io.Copy(ef, pe)
	go io.Copy(of, po)
	err := dep.Run()
	if err != nil {
		resp.Status = 2
		log.Print(errors.Wrap(err, "Coudn't process ssl order"), *o, string(b))
	} else {
		resp.Status = 3
	}
	b, _ = json.Marshal(resp)
	respCh <- b

}

func handleNewSiteOrder(o *order) {
	er := func() error {
		td, _ := ioutil.TempDir(os.TempDir(), "wpinst")
		//Writting deployment file
		x, _ := os.OpenFile(path.Join(td, "wp.yml"), os.O_WRONLY|os.O_CREATE, 0644)
		err := dockerTemplate.Execute(x, &ymlconf{
			DOCKER_REG: DOCKER_REG,
			OID:        o.Id,
			NODEID:     DNODEID})
		if err != nil {
			return errors.Wrap(err, "Couldn't Execute template")
		}
		x.Close()
		//Writting env variables
		envs := makeEnvFile(o.Wp)
		f, _ := os.OpenFile(path.Join(td, "env.env"), os.O_WRONLY|os.O_CREATE, 0644)
		for _, v := range envs {
			f.WriteString(fmt.Sprint(v, "\n"))
		}
		f.Close()

		dep := exec.Command("docker", "stack", "up", "-c", path.Join(td, "wp.yml"), fmt.Sprint("stack_wp_", o.Id))
		ef, _ := os.OpenFile("/var/log/wp/site/error.log", os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0644)
		of, _ := os.OpenFile("/var/log/wp/site/log.log", os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0644)
		po, _ := dep.StdoutPipe()
		pe, _ := dep.StderrPipe()
		go io.Copy(ef, pe)
		go io.Copy(of, po)
		if err = dep.Run(); err != nil {
			return errors.Wrapf(err, "Couldn't Launch docker stack %s", o.Id)
		}

		err = setupNginxConf(o)
		if err != nil {
			return errors.Wrapf(err, "Couldn't make nginx confile for order id %s", o.Id)
		}
		//Reloading nginx
		err = exec.Command("nginx", "-s", "reload").Run()
		if err != nil {
			return err
		}
		if o.Plan == ADVANCE {
			enableBackup(o)
		}
		return nil

	}()
	//Sending Response Message
	resp := new(responseMsg)
	resp.Id = o.Id
	resp.Type = o.Type
	resp.Status = 1 //For Safe state
	if er != nil {
		resp.Status = 2
		log.Print(errors.Wrap(er, "Couldn't process order ,"), *o)
	}
	b, _ := json.Marshal(resp)
	respCh <- b
	log.Print(er, string(b))
}

func setupNginxConf(o *order) error {
	c, err := client.NewClientWithOpts(client.FromEnv)
	if err != nil {
		return err
	}
	c.NegotiateAPIVersion(context.Background())
	var port uint16 = 0
	cs, err := c.ContainerList(context.Background(), types.ContainerListOptions{
		Filters: filters.NewArgs(filters.KeyValuePair{Key: "label", Value: fmt.Sprint("oid=", o.Id)})})
	if err != nil {
		return err
	}

	for _, v := range cs {
		for _, p := range v.Ports {
			if p.PrivatePort == 80 {
				port = p.PublicPort
				break
			}
		}
	}
	name := fmt.Sprint(o.Domain, ".conf")
	fp := path.Join(NGINX_CONF, "sites-available", name)
	f, _ := os.OpenFile(fp, os.O_WRONLY|os.O_CREATE, 0644)
	err = nginxTemplate.Execute(f, &nginxconf{fmt.Sprint("wp_", o.Id, ":", port), o.Domains, o.TempDomain, o.Id})
	if err != nil {
		return err
	}
	err = os.Symlink(fp, path.Join(NGINX_CONF, "conf.d", name))

	return err
}

func initNginxTemplate() {
	var err error
	nginxTemplate, err = template.ParseFiles("nginx.conf")
	if err != nil {
		panic(errors.Wrap(err, "Couldn't initalize nginx template"))
	}
}
func initDockerTemplate() {
	var err error
	dockerTemplate, err = template.ParseFiles("wp.yml")
	if err != nil {
		panic(errors.Wrap(err, "Couldn't initalize docker template"))
	}
}

func initLogger() {
	f, _ := os.OpenFile("/var/log/wp/worker.log", os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0644)
	log.SetOutput(f)

}

func main() {
	initNginxTemplate()
	initDockerTemplate()
	initLogger()
	r := getRedis()
	wg := new(sync.WaitGroup)
	wg.Add(2)
	go consumeRedis(r, wg)
	go responseConsumer(r, respCh, wg)
	wg.Wait()
}
