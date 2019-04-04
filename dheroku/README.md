# Dheroku

A small shell script designed like [dsh](https://www.netfort.gr.jp/~dancer/software/dsh.html.en) to ease Heroku management.

## Requirements

[Configured](https://devcenter.heroku.com/articles/heroku-cli#getting-started)) [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli)

## Configuration

```bash
mkdir -p ~/.dheroku/group
```

Then (for example) add a few groups:

```bash
touch  ~/.dheroku/group/{staging-eu,staging-ap, production-eu,production-ap}
```

Fill one of the created files with Heroku application names (one per line).

```bash
echo "
dahsboard-eu-staging
backend-eu-staging
" > ~/.dheroku/group/staging-eu
```

## Usage

Then you can run the same command on each application of a group:

Here you can read application configuration:

```bash
dheroku.sh  -g staging-eu config
```

Here you put all the application of the staging-eu in maintenance mode:

```bash
dheroku.sh  -g staging-eu maintenance:on
```

## Help

```bash
dheroku/dheroku.sh
```

## Local installation

If you're using ZSH and [zplug](https://github.com/zplug/zplug), add the following line to your ZSH config:

```bash
zplug "FinalCAD/devops_tools", as:command, use:"dheroku/dheroku.sh", rename-to:dheroku
```

Then this script will be accessible as `dheroku` instead of `dheroku.sh`
