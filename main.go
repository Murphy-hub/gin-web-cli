package main

import (
	"embed"
	"os"

	"github.com/Murphy-hub/gin-web-cli/cmd"
	"github.com/Murphy-hub/gin-web-cli/internal/tfs"
	"github.com/urfave/cli/v2"
	"go.uber.org/zap"
)

//go:embed tpls
var f embed.FS

var VERSION = "v10.4.0"

func main() {
	defer func() {
		_ = zap.S().Sync()
	}()

	// Set the embed.FS to the fs package
	tfs.SetEFS(f)

	logger, err := zap.NewDevelopmentConfig().Build(zap.WithCaller(false))
	if err != nil {
		panic(err)
	}
	zap.ReplaceGlobals(logger)

	app := cli.NewApp()
	app.Name = "gin-web-cli"
	app.Version = VERSION
	app.Usage = "A command line tool for [gin-web](https://github.com/Murphy-hub/gin-admin)."
	app.Authors = append(app.Authors, &cli.Author{
		Name:  "ZhangShuai",
		Email: "shuai.zhang@plaso.me",
	})
	app.Commands = []*cli.Command{
		cmd.Version(VERSION),
		cmd.New(),
		cmd.Generate(),
		cmd.Remove(),
	}

	if err := app.Run(os.Args); err != nil {
		panic(err)
	}
}
