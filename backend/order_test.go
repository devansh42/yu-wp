package main

import (
	"bytes"
	"context"
	"fmt"
	"os"
	"os/exec"
	"testing"

	"github.com/labstack/echo"
)

func TestGetNodeList(t *testing.T) {
	fname := "/tmp/nodelist"
	f, err := os.OpenFile(fname, os.O_WRONLY, 0644)
	if err != nil {
		t.Error(err)
	}
	b := new(bytes.Buffer)
	b.Write([]byte("ededed hostname ww.go"))
	b.Write([]byte("\n"))
	b.Write([]byte("eded dededhu dheudhedu"))
	_, err = f.Write(b.Bytes())
	if err != nil {
		t.Error(err)
	}
	f.Close()
	NODESFILE = fname
	ns := getNodeList()
	for _, v := range ns {
		t.Log(v.Id, v.Hostname, v.Domain)
	}

}

func TestUserCreation(t *testing.T) {
	MYSQL_HOST = "localhost"
	MYSQL_PASSWD = "root"
	db, err := getDB()
	if err != nil {
		t.Error(err)
	}
	tx, err := db.Begin()
	if err != nil {
		t.Error(err)
	}
	username := "demo"
	passwd := "root1234"
	dbname := "demodb"
	err = createUserAndDB(tx, username, passwd, dbname)
	if err != nil {
		tx.Rollback()
		t.Error(err)
	}
	tx.Commit()
	tx.Exec(fmt.Sprint("drop database ", dbname))
	tx.Exec(fmt.Sprint("drop user ", username))
	tx.Commit()
}

func TesGetTempDomain(t *testing.T) {
	o := new(order)
	o.Id = "123"

	o.TempDomain = "demotemp.bsnl.online"
	DOTOKEN = "DOTOKEN"
	err := setTempDomain("ozai.bsnl.online", o)
	if err != nil {
		t.Error(err)
	}
	t.Log("Success")
}

func TestNewOrderEndpoint(t *testing.T) {
	e := getApiServer()
	e.POST("/test", func(c echo.Context) error {
		o := new(order)
		unbindRequestBody(o, c)
		t.Log(*o)
		return nil
	})
	go e.Start(":8080")
	c := exec.Command("curl", "-v", "-X", "POST", "-H", "Content-Type:application/json", "-d", "@/tmp/data.json", "http://localhost:8080/test")
	c.Run()
	defer e.Shutdown(context.Background())

}
