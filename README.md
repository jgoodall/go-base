# Golang Base Project

Clone this repository, then update `app-name` and `author-name` in the `main.go` file. Then setup git and go modules:

```sh
rm -rf .git
git init
go mod init <module-path>
go mod tidy
make
```

Project setup is based on [golang-standards/project-layout repository](https://github.com/golang-standards/project-layout). Private application and library code should go in `internal`. Library code that's ok to use by external applications should go in `pkg`.
