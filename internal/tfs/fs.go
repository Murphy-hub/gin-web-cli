package tfs

import (
	"bytes"
	"os"
	"path/filepath"
	"text/template"

	"github.com/Murphy-hub/gin-web-cli/internal/utils"
)

var Ins FS = NewEmbedFS()

func SetIns(ins FS) {
	Ins = ins
}

type FS interface {
	ReadFile(name string) ([]byte, error)
	ParseTpl(name string, data interface{}) ([]byte, error)
}

type osFS struct {
	dir string
}

func NewOSFS(dir string) FS {
	return &osFS{dir: dir}
}

func (fs *osFS) ReadFile(name string) ([]byte, error) {
	return os.ReadFile(filepath.Join(fs.dir, name))
}

func (fs *osFS) ParseTpl(name string, data interface{}) ([]byte, error) {
	tplBytes, err := fs.ReadFile(name)
	if err != nil {
		return nil, err
	}
	return parseTplData(string(tplBytes), data)
}

func parseTplData(text string, data interface{}) ([]byte, error) {
	t, err := template.New("").Funcs(utils.FuncMap).Parse(text)
	if err != nil {
		return nil, err
	}
	buf := new(bytes.Buffer)
	if err := t.Execute(buf, data); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}
