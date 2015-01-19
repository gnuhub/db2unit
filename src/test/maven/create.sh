#!/bin/bash
# This file is part of db2unit: A unit testing framework for DB2 LUW.
# Copyright (C)  2014, 2015  Andres Gomez Casanova (@AngocA)
#
# db2unit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# db2unit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Andres Gomez Casanova <angocaATyahooDOTcom>

# Installs DB2, creates an instance and a database.
#
# Version: 2015-01-14 V2_BETA
# Author: Andres Gomez Casanova (AngocA)
# Made in COLOMBIA.

TEMP_WIKI_DOC=/tmp/db2-wiki
DB2_INSTALLER=v10.5fp5_linuxx64_server_t.tar.gz
DB2_RSP_FILE_INSTALL=https://raw.githubusercontent.com/angoca/db2-docker/master/install/10.5/server_t/db2server_t.rsp
DB2_RSP_FILE_INSTANCE=https://raw.githubusercontent.com/angoca/db2-docker/master/instance/server_t/db2server_t.rsp
INSTANCE_NAME=db2inst1
DB2_DIR=/opt/ibm/db2/V10.5

DIR=$(strings /var/db2/global.reg | grep -s '^\/' | sort | uniq | grep -v sqllib | grep -v das | head -1)
echo $DIR
if [ ! -x ${DIR}/bin/db2 ] ; then
 echo "DB2 non installed"
 wget https://raw.githubusercontent.com/wiki/angoca/db2-docker/db2-link-server_t.md -o ${TEMP_WIKI_DOC}
 URL=$(cat ${TEMP_WIKI_DOC} | tail -1)
 echo ${URL}
 wget ${URL}
 tar -zvxf ${DB2_INSTALLER}
 wget ${DB2_RSP_FILE_INSTALL}
 cd server_t
 ./db2setup -r /tmp/${DB2_RESP_FILE_INSTALL}
else
 echo "Installed"
fi

INSTANCE_NAME=$(${DIR}/instance/db2ilist | grep db2inst1)
if [ "${INSTANCE_NAME}" != "db2inst1" ] ; then
 echo "Instance ${INSTANCE_NAME} does not exist"
 ${DB2_DIR}/instance/db2isetup -r /tmp/${DB2_RESP_FILE}
 su -c "db2start" - db2inst1
fi

su -c "db2 create db db2unit" - db2inst1

echo "Environment was configured"
