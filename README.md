This project for long running or productive Docker and Docker Container instances. Containers need a mechanism for managing logfiles. Otherwise your disk space will swapped full by logfiles and you lose your instance.

This container can crawl for logfiles and rotate them. It is a side-car container
for containers that write logfiles and need a log rotation mechanism. Just hook up some containers and define your
backup volumes.

# Make It Short

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

# How To Attach to Logs

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

# Customize Log File Ending

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

# Set the Number of Rotations

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

# Set Maximum File size

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

# Set Log File compression

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

# Set the Output directory

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

# Set the Cron Schedule

You can set the cron schedule independently of the logrotate interval. You can override
the default schedule with the enviroment variable `LOGROTATE_CRONSCHEDULE`.

Example:

~~~~
$ docker run -d \
	-v /var/lib/docker/containers:/var/lib/docker/containers \
	-v /var/log/docker:/var/log/docker \
	-e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "LOGROTATE_INTERVAL=hourly" \
  -e "LOGROTATE_CRONSCHEDULE=* * * * * *" \
  blacklabelops/logrotate
~~~~

# Log and View the Logrotate Output

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
  -e "LOGROTATE_CRONSCHEDULE=* * * * * *" \
  -e "LOGROTATE_LOGFILE=/logs/logrotatecron.log" \
  blacklabelops/logrotate
~~~~

> You will be able to see logrotate output every minute in file logs/logrotatecron.log

# Log and View the Cron Output

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
  -e "LOGROTATE_CRONSCHEDULE=* * * * * *" \
  -e "LOG_FILE=/logs/cron.log" \
  blacklabelops/logrotate
~~~~

> You will be able to see cron output every minute in file logs/cron.log


## Vagrant

Vagrant is fabulous tool for pulling and spinning up virtual machines like docker with containers. I can configure my development and test environment and simply pull it online. And so can you! Install Vagrant and Virtualbox and spin it up. Change into the project folder and build the project on the spot!

~~~~
$ vagrant up
$ vagrant ssh
[vagrant@localhost ~]$ cd /vagrant
[vagrant@localhost ~]$ docker-compose up
~~~~

> Jenkins will be available on localhost:9200 on the host machine. Backups run
in background.

Vagrant does not leave any docker artifacts on your beloved desktop and the vagrant image can simply be destroyed and repulled if anything goes wrong. Test my project to your heart's content!

First install:

* [Vagrant](https://www.vagrantup.com/)
* [Virtualbox](https://www.virtualbox.org/)

## References

* [Logrotate](http://www.linuxcommand.org/man_pages/logrotate8.html)
* [Docker Homepage](https://www.docker.com/)
* [Docker Userguide](https://docs.docker.com/userguide/)
* [Vagrant](https://www.vagrantup.com/)
* [Virtualbox](https://www.virtualbox.org/)
