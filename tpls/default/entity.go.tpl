package entity

import (
    "{{.RootImportPath}}/internal/config"
    "{{.RootImportPath}}/pkg/structure"
	"{{.ModuleImportPath}}/schema"
)

{{$name := .Name}}

type Schema{{$name}} schema.{{$name}}

func (a Schema{{$name}}) To{{$name}}() *{{$name}} {
	item := new({{$name}})
	structure.Copy(a, item)
	return item
}

{{with .Comment}}// {{$name}} {{.}}{{else}}// 定义 `{{$name}}` 结构.{{end}}
type {{$name}} struct {
    {{- range .Fields}}{{$fieldName := .Name}}
	{{$fieldName}} {{.Type}} `{{with .GormTag}} gorm:"{{.}}"{{end}}{{with .CustomTag}} {{raw .}}{{end}}`{{with .Comment}}// {{.}}{{end}}
	{{- end}}
}

{{- if .TableName}}
func (a {{$name}}) TableName() string {
	return config.C.FormatTableName("{{.TableName}}")
}
{{- end}}

func (a {{$name}}) ToSchema{{$name}}() *schema.{{$name}} {
	item := new(schema.{{$name}})
	structure.Copy(a, item)
	return item
}

type {{$name}}s []*{{$name}}

func (a {{$name}}s) ToSchema{{$name}}s() []*schema.{{$name}} {
	list := make([]*schema.{{$name}}, len(a))
	for i, item := range a {
		list[i] = item.ToSchema{{$name}}()
	}
	return list
}
