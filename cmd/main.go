package main

import (
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/alecthomas/kingpin"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

// Version, GitSHA and BuildTime are injected in Makefile.
var (
	Version   string
	GoVersion string
	GitSHA    string
	BuildTime string
)

var (
	app      = kingpin.New("app-name", "Description")
	logLevel = app.Flag("log-level", "Log level to print to stderr").Short('l').Default("warn").Enum("info", "warn", "error")
	logJSON  = app.Flag("log-json", "Structured  JSON logging").Bool()
)

func main() {
	t, _ := strconv.Atoi(BuildTime)
	compiled := time.Unix(int64(t), 0)
	vers := fmt.Sprintf("version:\t%s\ngo version:\t%s\ngit commit:\t%s\ncompiled:\t%s\n", Version, GoVersion, GitSHA, compiled.String())

	app.Version(vers)
	app.Author("author-name")
	app.DefaultEnvars() // Default envar: <APP_NAME>_FLAG_NAME
	app.HelpFlag.Short('h')

	app.PreAction(func(c *kingpin.ParseContext) error {
		zerolog.SetGlobalLevel(zerolog.WarnLevel) // default
		if *logLevel == "info" {
			zerolog.SetGlobalLevel(zerolog.InfoLevel)
		} else if *logLevel == "error" {
			zerolog.SetGlobalLevel(zerolog.ErrorLevel)
		}
		if !*logJSON {
			log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr})
		}
		return nil
	})

	kingpin.MustParse(app.Parse(os.Args[1:]))

	// Do stuff

}
