package dal

import (
	"context"

	"{{.UtilImportPath}}"
	"{{.ModuleImportPath}}/entity"
	"{{.ModuleImportPath}}/schema"
	"{{.RootImportPath}}/pkg/errors"
	"gorm.io/gorm"
)

{{$name := .Name}}
{{$includeCreatedAt := .Include.CreatedAt}}
{{$includeStatus := .Include.Status}}
{{$treeTpl := eq .TplType "tree"}}

// Get{{$name}}DB 获取 {{lowerSpace .Name}} 存储实例
func Get{{$name}}DB(ctx context.Context, defDB *gorm.DB) *gorm.DB {
	return util.GetDB(ctx, defDB).Model(new(entity.{{$name}}))
}

{{with .Comment}}// {{$name}} {{.}}{{else}}// `{{$name}}` 定义 `{{$name}}` 数据访问对象。{{end}}
type {{$name}} struct {
	DB *gorm.DB
}

// Query 根据提供的参数和选项从数据库中查询 {{lowerSpacePlural .Name}}
func (a *{{$name}}) Query(ctx context.Context, params schema.{{$name}}QueryParam, opts ...schema.{{$name}}QueryOptions) (*schema.{{$name}}QueryResult, error) {
	var opt schema.{{$name}}QueryOptions
	if len(opts) > 0 {
		opt = opts[0]
	}

	db := Get{{$name}}DB(ctx, a.DB)

	{{- if $treeTpl}}
	if v:= params.InIDs; len(v) > 0 {
		db = db.Where("id IN ?", v)
	}
	{{- end}}

    {{- range .Fields}}{{$type := .Type}}{{$fieldName := .Name}}
    {{- with .Query}}
	if v := params.{{.Name}}; {{with .IfCond}}{{.}}{{else}}{{convIfCond $type}}{{end}} {
		db = db.Where("{{lowerUnderline $fieldName}} {{.OP}} ?", {{if .Args}}{{raw .Args}}{{else}}{{if eq .OP "LIKE"}}"%"+v+"%"{{else}}v{{end}}{{end}})
	}
    {{- end}}
    {{- end}}

	var list entity.{{plural .Name}}
	pageResult, err := util.WrapPageQuery(ctx, db, params.PaginationParam, opt.QueryOptions, &list)
	if err != nil {
		return nil, errors.WithStack(err)
	}

	queryResult := &schema.{{$name}}QueryResult{
		PageResult: pageResult,
		Data:       list.ToSchema{{$name}}s(),
	}
	return queryResult, nil
}

// Get 从数据库中获取指定的 {{lowerSpacePlural .Name}}
func (a *{{$name}}) Get(ctx context.Context, id int, opts ...schema.{{$name}}QueryOptions) (*schema.{{$name}}, error) {
	var opt schema.{{$name}}QueryOptions
	if len(opts) > 0 {
		opt = opts[0]
	}

	item := new(entity.{{$name}})
	ok, err := util.FindOne(ctx, Get{{$name}}DB(ctx, a.DB).Where("id=?", id), opt.QueryOptions, item)
	if err != nil {
		return nil, errors.WithStack(err)
	} else if !ok {
		return nil, nil
	}
	return item.ToSchema{{$name}}(), nil
}

// Exists 检查数据库中是否存在指定的 {{lowerSpace .Name}}
func (a *{{$name}}) Exists(ctx context.Context, id int) (bool, error) {
	ok, err := util.Exists(ctx, Get{{$name}}DB(ctx, a.DB).Where("id=?", id))
	return ok, errors.WithStack(err)
}

{{- range .Fields}}
{{- if .Unique}}
{{- if $treeTpl}}
// Exists 检查数据库中是否存在指定的 {{lowerSpace .Name}}
func (a *{{$name}}) Exists{{.Name}}(ctx context.Context, parentID int, {{lowerCamel .Name}} string) (bool, error) {
	ok, err := util.Exists(ctx, Get{{$name}}DB(ctx, a.DB).Where("parent_id=? AND {{lowerUnderline .Name}}=?", parentID, {{lowerCamel .Name}}))
	return ok, errors.WithStack(err)
}
{{- else}}
// Exists 检查数据库中是否存在指定的 {{lowerSpace .Name}}
func (a *{{$name}}) Exists{{.Name}}(ctx context.Context, {{lowerCamel .Name}} string) (bool, error) {
	ok, err := util.Exists(ctx, Get{{$name}}DB(ctx, a.DB).Where("{{lowerUnderline .Name}}=?", {{lowerCamel .Name}}))
	return ok, errors.WithStack(err)
}
{{- end}}
{{- end}}
{{- end}}

// Create 创建一个新的 {{lowerSpace .Name}}
func (a *{{$name}}) Create(ctx context.Context, item schema.{{$name}}) (*schema.{{$name}}, error) {
    sitem := entity.Schema{{$name}}(item).To{{$name}}()
	result := Get{{$name}}DB(ctx, a.DB).Create(sitem)
	return sitem.ToSchema{{$name}}(), errors.WithStack(result.Error)
}

// Update 更新数据库中指定的 {{lowerSpace .Name}}
func (a *{{$name}}) Update(ctx context.Context, item schema.{{$name}}) error {
    eitem := entity.Schema{{$name}}(item).To{{$name}}()
	result := Get{{$name}}DB(ctx, a.DB).Where("id=?", item.ID).Select("*"){{if $includeCreatedAt}}.Omit("created_time"){{end}}.Updates(eitem)
	return errors.WithStack(result.Error)
}

// Delete 从数据库中删除指定的 {{lowerSpace .Name}}
func (a *{{$name}}) Delete(ctx context.Context, id int) error {
	result := Get{{$name}}DB(ctx, a.DB).Where("id=?", id).Delete(new(entity.{{$name}}))
	return errors.WithStack(result.Error)
}

{{- if $treeTpl}}
// UpdateParentPath 更新指定的 {{lowerSpace .Name}} 的父路径。
func (a *{{$name}}) UpdateParentPath(ctx context.Context, id int, parentPath string) error {
	result := Get{{$name}}DB(ctx, a.DB).Where("id=?", id).Update("parent_path", parentPath)
	return errors.WithStack(result.Error)
}

{{- if $includeStatus}}
// UpdateStatusByParentPath 更新父路径以所提供的父路径开头的所有 {{lowerSpace .Name}} 的状态。
func (a *{{$name}}) UpdateStatusByParentPath(ctx context.Context, parentPath, status string) error {
	result := Get{{$name}}DB(ctx, a.DB).Where("parent_path like ?", parentPath+"%").Update("status", status)
	return errors.WithStack(result.Error)
}
{{- end}}
{{- end}}