---
categories: docker
---

## Goal
I just need a MySQL instance for development purpose, but with persisted data.

## Storage
There are 2 ways to persist MySQL data, [docker volume](https://docs.docker.com/storage/volumes/), or mount a directory on the host machine. For my purpose, I use docker volume.

## Create Volume
``` bash
$ docker volume create sumpdatavolume
$ docker volume ls
(... snip ...)
local     sumpdatavolume
```

### Run MySQL
Run MySQL, create a test db and table.
``` bash
$ docker run --name sumpdatamysql -d -p 3306:3306 -e MYSQL_ROOT_PASSWORD=myrootpswd -v sumpdatavolume:/var/lib/mysql mysql
$ docker exec -it sumpdatamysql bash
bash-4.4# mysql -pmyrootpswd
mysql> create database test;
use test;
create table test(id int, name varchar(10));
insert into test(id, name) values (1,"John"), (2, "Mike");
select * from test;
+------+------+
| id   | name |
+------+------+
|    1 | John |
|    2 | Mike |
+------+------+
```

### Check persistent data

Remove the existing container and recreate MySQL using the same docker volume.
``` bash
$ docker stop sumpdatamysql
$ docker rm sumpdatamysql
$ docker run --name sumpdatamysql -d -p 3306:3306 -e MYSQL_ROOT_PASSWORD=myrootpswd -v sumpdatavolume:/var/lib/mysql mysql
$ docker exec -it sumpdatamysql bash
mysql -pmyrootpswd
use test;
select * from test;
+------+------+
| id   | name |
+------+------+
|    1 | John |
|    2 | Mike |
+------+------+
```
As shown above in `select` statement, the same data is there.

