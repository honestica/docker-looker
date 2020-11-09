#!/bin/sh

#
# This is the startup script for Looker using OpenJDK11.  Looker supports
# OpenJDK11 starting with the 7.16 release
#

JAVA_VER=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | sed '/^1\./s///' | cut -d'.' -f1)
if [ "$JAVA_VER" -ne 11 ]; then
  WHERE=`which java`
  echo "This script runs with OpenJDK11, your executable $WHERE has Java major version $JAVA_VER"
  exit 1
fi

# Extra Java startup args and Looker startup args.  These can also be set in
# a file named lookerstart.cfg
JMXARGS="-Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.port=9910 -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.ssl=false -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.local.only=false -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.authenticate=true -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.access.file=${HOME}/.lookerjmx/jmxremote.access -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.password.file=${HOME}/.lookerjmx/jmxremote.password"

# to set up JMX monitoring, add JMXARGS to JAVAARGS
JAVAARGS=""
LOOKERARGS="--no-daemonize"

# check if --no-ssl is specified in LOOKERARGS and set protocol accordingly
PROTOCOL=""

echo "${LOOKERARGS}" | grep -q "\-\-no\-ssl"
if [ $? -eq 0 ]
then
	PROTOCOL='http'
else
	PROTOCOL='https'
fi
LOOKERPORT=${LOOKERPORT:-"9999"}

start() {
    fixcrypt
    java \
  -XX:+UseG1GC -XX:MaxGCPauseMillis=2000 -XX:MinRAMPercentage=50 -XX:MaxRAMPercentage=80 \
  -Xlog:gc*,gc+ref=debug,gc+heap=debug,gc+age=debug:file=/tmp/gc-%p-%t.log:tags,uptime,time,level:filecount=7,filesize=10m \
  ${JAVAARGS} \
  -jar looker.jar start ${LOOKERARGS}
}


fixcrypt() {
    CRYPTEXIST=`/sbin/ldconfig -p | grep -c '\slibcrypt.so\s'`

    if [ $CRYPTEXIST -eq 0 ]; then
        if [ ! -d .tmp ]; then
            mkdir .tmp
        fi
        CRYPTLN=`/sbin/ldconfig -p | grep '\slibcrypt\.so\.[[:digit:]]' | awk '{print $(NF)}'`
        ln -s -f $CRYPTLN `pwd`/.tmp/libcrypt.so
        export LD_LIBRARY_PATH=`pwd`/.tmp/:$LD_LIBRARY_PATH
    fi
}

case "$1" in
  start)
    start
	;;
  status)
        curl -ks ${PROTOCOL}://127.0.0.1:${LOOKERPORT}/alive > /dev/null 2>&1
        if [ $? -eq 7 ]; then
          echo "Status:Looker Web Application stopped"
          exit 7
        else
          echo "Status:Looker Web Application running"
          exit 0
        fi
        ;;
  *)
        java -jar looker.jar $*
        ;;
esac

exit 0
