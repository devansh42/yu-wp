package main

import (
	"bytes"
	"context"
	"os/exec"
	"testing"
	"time"

	"github.com/docker/docker/api/types/filters"
	"github.com/docker/docker/client"

	"github.com/docker/docker/api/types"
)

func TestNginxTemplate(t *testing.T) {
	initNginxTemplate()
	x := map[string]interface{}{"OID": 786, "BindAddr": "localhost:8080", "ServerNames": "www.google.com www.facebook.com", "TempName": "temp.bsnl.online"}
	b := new(bytes.Buffer)
	nginxTemplate.Execute(b, &x)
	t.Log(string(b.Bytes()))
}

func TestDockerTemplate(t *testing.T) {
	initDockerTemplate()
	x := map[string]interface{}{
		"OID":        1233,
		"NODEID":     "doddle",
		"DOCKER_REG": "google.com:8200"}

	b := new(bytes.Buffer)
	dockerTemplate.Execute(b, &x)
	t.Log(string(b.Bytes()))
}

func TestContainerListing(t *testing.T) {
	c := exec.Command("docker", "run", "-d", "--label name=devansh42", "nginx:alpine")
	c.Run()
	cli, _ := client.NewEnvClient()
	cs, err := cli.ContainerList(context.Background(), types.ContainerListOptions{
		Filters: filters.NewArgs(filters.KeyValuePair{Key: "label", Value: "name=devansh42"})})
	if err != nil {
		t.Error(err)
	}
	for _, v := range cs {
		t.Log(v.ID)
		d := time.Hour * 1
		cli.ContainerStop(context.Background(), v.ID, &d)
		break
	}

}
