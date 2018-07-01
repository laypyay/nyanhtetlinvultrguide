#!/bin/bash
_USER_=webuser
_GROUP__=webgroup
useradd $_USER_
addgroup $_GROUP__
adduser $_USER_ $_GROUP__
apt update && apt install sudo -y
echo "%${_GROUP__} ALL=(ALL:ALL) NOPASSWD:/usr/bin/nginxv" >> /etc/sudoers