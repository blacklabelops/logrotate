# Dockerized Logrotate

[![Open Issues](https://img.shields.io/github/issues/blacklabelops/logrotate.svg)](https://github.com/blacklabelops/logrotate/issues) [![Stars on GitHub](https://img.shields.io/github/stars/blacklabelops/logrotate.svg)](https://github.com/blacklabelops/logrotate/stargazers)
[![Docker Stars](https://img.shields.io/docker/stars/blacklabelops/logrotate.svg)](https://hub.docker.com/r/blacklabelops/logrotate/) [![Docker Pulls](https://img.shields.io/docker/pulls/blacklabelops/logrotate.svg)](https://hub.docker.com/r/blacklabelops/logrotate/) [![](https://badge.imagelayers.io/blacklabelops/logrotate:latest.svg)](https://imagelayers.io/?images=blacklabelops/logrotate:latest 'Get your own badge on imagelayers.io')

This container can crawl for logfiles and rotate them. It is a side-car container
for containers that write logfiles and need a log rotation mechanism. Just hook up some containers and define your
backup volumes.

## Supported tags and respective Dockerfile links

| Distribution | Version      | Tag          | Dockerfile |
|--------------|--------------|--------------|------------|
| Logrotate Alpine | latest, 1.3 | latest, 1.3 | [Dockerfile](https://github.com/blacklabelops/logrotate/blob/master/Dockerfile) |

## Make It Short

In short, this container can rotate all your Docker logfiles just by typing:

~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  blacklabelops/logrotate
~~~~

> This will rotate all your Docker logfiles on a daily basis up to 5 times.

You want to do it hourly? Just type:

~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "LOGROTATE_INTERVAL=hourly" \
  blacklabelops/logrotate
~~~~

> This will put logrotate on an hourly schedule.

## How To Attach to Logs

In order to attach the side-car container to your logs you have to hook your log file folders inside volumes. Afterwards
specify the folders logrotate should crawl for log files. The container attaches by default to any file ending with **.log** inside the specified folders.

Environment variable for specifying log folders: `LOGS_DIRECTORIES`. Each directory must be separated by a whitespace character.

Example:

~~~~
LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker
~~~~

Example Logrotating all Docker logfiles:

~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  blacklabelops/logrotate
~~~~

> This will logrotate any logfile(s) under /var/lib/docker/containers, /var/log/docker (or subdirectories of them).

## Customize Log File Ending

You can define the file endings fluentd will attach to. The container will by default crawl for
files ending with **.log**. This can be overriden and extended to any amount of file endings.

Example:

~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "LOG_FILE_ENDINGS=json xml" \
  blacklabelops/logrotate
~~~~

> Crawls for file endings .json and .xml.

## Set the Log interval

Logrotate can rotate logfile according to the following intervals:

* `hourly`
* `daily`
* `weekly`
* `monthly`
* `yearly`

You can override the default setting with the environment variable `LOGROTATE_INTERVAL`.

Example:

~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "LOGROTATE_INTERVAL=hourly" \
  blacklabelops/logrotate
~~~~

> This will logrotate logfile(s) on hourly basis.

## Set the Number of Rotations

The default number of rotations is five. Further rotations will delete old logfiles. You
can override the default setting with the environment variable `LOGROTATE_COPIES`.

Example:

~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "LOGROTATE_COPIES=10" \
  blacklabelops/logrotate
~~~~

> Will create 10 daily logs before deleting old logs.

## Set Maximum File size

Logrotate can do additional rotates, when the logfile exceeds a certain file size. You can specifiy file size rotation
with the environment variable `LOGROTATE_SIZE`.

Valid example values:

* `100k`: Will rotate when log file exceeds 100 kilobytes.
* `100M`: Will rotate when log file exceeds 100 Megabytes.
* `100G`: Will rotate when log file exceeds 100 Gigabytes.

~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "LOGROTATE_SIZE=10M" \
  blacklabelops/logrotate
~~~~

> This will logrotate when logfile(s) reaches 10M+.

## Set Log File compression

The default logrotate setting is `nocompress`. In order to enable logfile compression
you can set the environment variable `LOGROTATE_COMPRESSION` to `compress`.

Example:

~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "LOGROTATE_COMPRESSION=compress" \
  blacklabelops/logrotate
~~~~

> This will compress the logrotated logs.

## Turn Off Log File delaycompress

When compression is turned on, delaycompress will be set by default. To turn this off,
set the environment variable `LOGROTATE_DELAYCOMPRESS` to `false`.

Example:
~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "LOGROTATE_COMPRESSION=compress" \
  -e "LOGROTATE_DELAYCOMPRESS=false" \
  blacklabelops/logrotate
~~~~

> This will compress all logrotated logs, including the most recent one.

## Set logrotate mode

By default, logrotate will use copytruncate mode to create a new rotated file, however
certain log collection applications won't work properly with this configuration. To use a different
option, such as `create <mode> <owner> <group>`, set the environment variable `LOGROTATE_MODE`.

Example:
~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "LOGROTATE_MODE=create 0644"
  blacklabelops/logrotate
~~~~

> This will rename the current log file, and create a new one in its place

## Set the Output directory

By default, logrotate will rotate logs in their respective directories. You can
specify a directory for keeping old logfiles with the environment variable `LOGROTATE_OLDDIR`. You can specify a full or relative path.

Example:

~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -v $(pwd)/logs:/logs/ \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "LOGROTATE_OLDDIR=/logs" \
  blacklabelops/logrotate
~~~~

> Will move old logfiles in the local directory logs/.

## Set the Cron Schedule

You can set the cron schedule independently of the logrotate interval. You can override
the default schedule with the enviroment variable `LOGROTATE_CRONSCHEDULE`.

Example:

~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "LOGROTATE_CRONSCHEDULE=* * * * * *" \
  blacklabelops/logrotate
~~~~

> This will logrotate on go-cron schedule \* \* \* \* \* \* (every second).

## Log and View the Logrotate Output

You can specify a logfile for the periodical logrotate execution. The file
is specified using the environment variable `LOGROTATE_LOGFILE`. Must be a full path!

Example:

~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -v $(pwd)/logs:/logs \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "LOGROTATE_INTERVAL=hourly" \
  -e "LOGROTATE_LOGFILE=/logs/logrotatecron.log" \
  blacklabelops/logrotate
~~~~

> You will be able to see logrotate output every minute in file logs/logrotatecron.log.

## Logrotate Commandline Parameters

You can define the logrotate commandline parameters with the environment variable LOGROTATE_PARAMETERS.

*v*: Verbose

*d*: Debug, Logrotate will be emulated but never executed!

*f*: Force

Example for a typical testrun:

~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -v $(pwd)/logs:/logs \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "LOGROTATE_PARAMETERS=vdf" \
  -e "LOG_FILE=/logs/cron.log" \
  blacklabelops/logrotate
~~~~

> Will run logrotate with: /usr/bin/logrotate -dvf

## Logrotate Status File

Logrotate must remember when files have been rotated when using time intervals, e.g. 'daily'. The status file will be written by default to the container volume but you can specify a custom location with the environment variable LOGROTATE_STATUSFILE.

Example:

~~~~
$ docker run -d \
  -e "LOGROTATE_INTERVAL=hourly" \
  -e "LOGROTATE_STATUSFILE=/logrotate-status/logrotate.status" \
  -e "ALL_LOGS_DIRECTORIES=/var/log" \
  -e "LOGROTATE_PARAMETERS=vf" \
  blacklabelops/logrotate
~~~~

> Writes the latest status file each logrotation. Reads status files at each start.

## Log and View the Cron Output

You can specify a separate logfile for cron. The file
is specified using the environment variable `LOG_FILE`. Must be a full path!

Example:

~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -v $(pwd)/logs:/logs \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "LOGROTATE_INTERVAL=hourly" \
  -e "LOG_FILE=/logs/cron.log" \
  blacklabelops/logrotate
~~~~

> You will be able to see cron output every minute in file logs/cron.log.

## Setting a Date Extension

With Logrotate it is possible to split files and name them by the date they were generated when used with `LOGROTATE_DATEFORMAT`. By setting `LOGROTATE_DATEFORMAT` you will enable the Logrotate `dateext` option.

The default Logrotate format is `-%Y%m%d`, to enable the defaults `LOGROTATE_DATEFORMAT` should be set to this.

Example:

~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -e "LOGROTATE_INTERVAL=daily" \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "LOGROTATE_DATEFORMAT=-%Y%m%d" \
  blacklabelops/logrotate
~~~~

> This will set logrotate to split files and name them by date format -%Y%m%d.

## Setting MaxAge and minsize

Maxage and minsize for logs can be configured with the environment variables `LOGROTATE_MAXAGE` and `LOGROTATE_MINSIZE`.

* Maxage: `Remove  rotated  logs  older  than <count> days. The age is only checked if the logfile is to be rotated.`
* Minsize: `Log files are rotated when they grow bigger than size bytes, but not before the  additionally  specified  time  interval  (daily, weekly, monthly, or yearly).  The related size option is similar except that it is mutually  exclusive  with  the  time  interval options,  and  it  causes log files to be rotated without regard for the last rotation time.  When minsize is used, both the size and timestamp of a log file are considered.`

> [Source](http://manpages.ubuntu.com/manpages/yakkety/man8/logrotate.8.html)

Size Parameter: `If size is followed by k, the size is assumed to  be  in  kilo-bytes.  If the M is used, the size is in megabytes, and if G is used, the size is in gigabytes. So size 100,  size  100k,  size 100M and size 100G are all valid.`

> [Source](http://manpages.ubuntu.com/manpages/yakkety/man8/logrotate.8.html)

Example:

~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "LOGROTATE_MAXAGE=60" \
  -e "LOGROTATE_MINSIZE=100k" \
  blacklabelops/logrotate
~~~~

> Maxage is sixty days and minsize is 100 kilobytes.

## Custom Skript execution

Sometimes it is necessary to signal the process in order to start logrotation or stop logrotation. You
can do this with the environment variables `LOGROTATE_PREROTATE_COMMAND` and `LOGROTATE_POSTROTATE_COMMAND`.

Example:

~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "LOGROTATE_PREROTATE_COMMAND=/usr/bin/yourscript.sh" \
  -e "LOGROTATE_POSTROTATE_COMMAND=/usr/bin/killall -HUP httpd" \
  blacklabelops/logrotate
~~~~

> Will print messages before and after rotation.

## Disable Auto Update

With Logrotate by default it auto update its logrotate configuration file to ensure it only captures all the intended log file in the `LOGS_DIRECTORIES` (before it rotates the log files). It is possible to disable auto update when used with `LOGROTATE_AUTOUPDATE`. By setting `LOGROTATE_AUTOUPDATE` (to not equal true) you will disable the auto update of Logrotate.

The default `LOGROTATE_AUTOUPDATE` is `true`, to disable the defaults `LOGROTATE_AUTOUPDATE` should be set not equal `true`.

Example:

~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "LOGROTATE_AUTOUPDATE=false" \
  blacklabelops/logrotate
~~~~

> This will disable logrotate configuration file update (when logrotate action is triggering).

# Set Time Zone

With Logrotate by default it logrotate logs in `UTC` time zone. It is possible to set time zone when used with `TZ`. By setting `TZ` (to a valid time zone) it will logrotate logs in the specified time zone.

The default `TZ` is `""`, to set to different time zone. E.g `Australia/Melbourne`.

Example:

~~~~
$ docker run -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "TZ=Australia/Melbourne" \
  blacklabelops/logrotate
~~~~

> This will logrotate in Australia/Melbourne time zone.

## Used in Kubernetes

When we run container in Kubernetes, we can use the logrotate container to rotate the logs. As we create

an DaemonSet in cluster ,we can deploy an logrotate container in every nodes of the cluster.

```sh
# kubectl create -f logrotate_ds.yaml
daemonset "logrotate" created
```

## References

* [Logrotate](http://www.linuxcommand.org/man_pages/logrotate8.html)
* [Docker Homepage](https://www.docker.com/)
* [Docker Userguide](https://docs.docker.com/userguide/)
