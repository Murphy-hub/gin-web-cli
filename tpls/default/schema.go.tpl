package schema

import (

	{{if .TableName}}"{{.RootImportPath}}/internal/config"{{end}}
	"{{.UtilImportPath}}"
)

{{$name := .Name}}
{{$includeSequence := .Include.Sequence}}
{{$treeTpl := eq .TplType "tree"}}

{{with .Comment}}// {{$name}} {{.}}{{else}}// 定义 `{{$name}}` 结构.{{end}}
type {{$name}} struct {
    {{- range .Fields}}{{$fieldName := .Name}}
	{{$fieldName}} {{.Type}} `json:"{{.JSONTag}}"{{with .CustomTag}} {{raw .}}{{end}}`{{with .Comment}}// {{.}}{{end}}
	{{- end}}
}

// {{$name}}QueryParam 为`{{$name}}`结构定义查询参数。
type {{$name}}QueryParam struct {
	util.PaginationParam
	{{if $treeTpl}}InIDs []string `form:"-"`{{- end}}
	{{- range .Fields}}{{$fieldName := .Name}}{{$type :=.Type}}
	{{- with .Query}}
	{{.Name}} {{$type}} `form:"{{with .FormTag}}{{.}}{{else}}-{{end}}"{{with .BindingTag}} binding:"{{.}}"{{end}}{{with .CustomTag}} {{raw .}}{{end}}`{{with .Comment}}// {{.}}{{end}}
	{{- end}}
	{{- end}}
}

// {{$name}}QueryOptions 定义 `{{$name}}` 结构的查询选项
type {{$name}}QueryOptions struct {
	util.QueryOptions
}

// {{$name}}QueryResult 定义 `{{$name}}` 结构的查询结果
type {{$name}}QueryResult struct {
	Data       {{plural .Name}}
	PageResult *util.PaginationResult
}

// {{plural .Name}} 定义 `{{$name}}` 结构的切片
type {{plural .Name}} []*{{$name}}

{{- if $includeSequence}}
func (a {{plural .Name}}) Len() int {
	return len(a)
}

func (a {{plural .Name}}) Less(i, j int) bool {
	if a[i].Sequence == a[j].Sequence {
		return a[i].CreatedAt.Unix() > a[j].CreatedAt.Unix()
	}
	return a[i].Sequence > a[j].Sequence
}

func (a {{plural .Name}}) Swap(i, j int) {
	a[i], a[j] = a[j], a[i]
}
{{- end}}

{{- if $treeTpl}}
func (a {{plural .Name}}) ToMap() map[string]*{{$name}} {
	m := make(map[string]*{{$name}})
	for _, item := range a {
		m[item.ID] = item
	}
	return m
}

func (a {{plural .Name}}) SplitParentIDs() []string {
	parentIDs := make([]string, 0, len(a))
	idMapper := make(map[string]struct{})
	for _, item := range a {
		if _, ok := idMapper[item.ID]; ok {
			continue
		}
		idMapper[item.ID] = struct{}{}
		if pp := item.ParentPath; pp != "" {
			for _, pid := range strings.Split(pp, util.TreePathDelimiter) {
				if pid == "" {
					continue
				}
				if _, ok := idMapper[pid]; ok {
					continue
				}
				parentIDs = append(parentIDs, pid)
				idMapper[pid] = struct{}{}
			}
		}
	}
	return parentIDs
}

func (a {{plural .Name}}) ToTree() {{plural .Name}} {
	var list {{plural .Name}}
	m := a.ToMap()
	for _, item := range a {
		if item.ParentID == "" {
			list = append(list, item)
			continue
		}
		if parent, ok := m[item.ParentID]; ok {
			if parent.Children == nil {
				children := {{plural .Name}}{item}
				parent.Children = &children
				continue
			}
			*parent.Children = append(*parent.Children, item)
		}
	}
	return list
}
{{- end}}

// {{$name}}Form 定义用于创建 `{{$name}}` 结构的数据结构。
type {{$name}}Form struct {
    ID int `json:"id"`
	{{- range .Fields}}{{$fieldName := .Name}}{{$type :=.Type}}
	{{- with .Form}}
	{{.Name}} {{$type}} `json:"{{.JSONTag}}"{{with .BindingTag}} binding:"{{.}}"{{end}}{{with .CustomTag}} {{raw .}}{{end}}`{{with .Comment}}// {{.}}{{end}}
	{{- end}}
	{{- end}}
}

// Validate `{{$name}}Form` 结构的验证函数。
func (a *{{$name}}Form) Validate() error {
	return nil
}

// FillTo 将 `{{$name}}Form` 转换为 `{{$name}}` 对象。
func (a *{{$name}}Form) FillTo({{lowerCamel $name}} *{{$name}}) error {
	{{- range .Fields}}{{$fieldName := .Name}}
	{{- with .Form}}
	{{lowerCamel $name}}.{{$fieldName}} = a.{{.Name}}
	{{- end}}
    {{- end}}
	return nil
}
