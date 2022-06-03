#!/bin/sh
sudo yum install firewalld
systemctl start firewalld
touch /home/home-file
