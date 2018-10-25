#!/bin/sh
# -----------------------------------------------------------------------------
# Start Script for GEOSERVER
#
# $Id$
# -----------------------------------------------------------------------------

# Guard against misconfigured JAVA_HOME
if [ ! -z "$JAVA_HOME" -a ! -x "$JAVA_HOME"/bin/java ]; then
  echo "The JAVA_HOME environment variable is set but JAVA_HOME/bin/java"
  echo "is missing or not executable:"
  echo "    JAVA_HOME=$JAVA_HOME"
  echo "Please either set JAVA_HOME so that the Java runtime is JAVA_HOME/bin/java"
  echo "or unset JAVA_HOME to use the Java runtime on the PATH."
  exit 1
fi

# Find java from JAVA_HOME or PATH
if [ ! -z "$JAVA_HOME" ]; then
  _RUNJAVA="$JAVA_HOME"/bin/java
elif [ ! -z "$(which java)" ]; then
  _RUNJAVA=java
else
  echo "A Java runtime (java) was not found in JAVA_HOME/bin or on the PATH."
  echo "Please either set the JAVA_HOME environment variable so that the Java runtime"
  echo "is JAVA_HOME/bin/java or add the Java runtime to the PATH."
  exit 1
fi

if [ -z $GEOSERVER_HOME ]; then
  #If GEOSERVER_HOME not set then guess a few locations before giving
  # up and demanding user set it.
  if [ -r start.jar ]; then
     echo "GEOSERVER_HOME environment variable not found, using current "
     echo "directory.  If not set then running this script from other "
     echo "directories will not work in the future."
     export GEOSERVER_HOME=`pwd`
  else 
    if [ -r ../start.jar ]; then
      echo "GEOSERVER_HOME environment variable not found, using current "
      echo "location.  If not set then running this script from other "
      echo "directories will not work in the future."
      export GEOSERVER_HOME=`pwd`/..
    fi
  fi 

  if [ -z "$GEOSERVER_HOME" ]; then
    echo "The GEOSERVER_HOME environment variable is not defined"
    echo "This environment variable is needed to run this program"
    echo "Please set it to the directory where geoserver was installed"
    exit 1
  fi

fi

if [ ! -r "$GEOSERVER_HOME"/bin/startup.sh ]; then
  echo "The GEOSERVER_HOME environment variable is not defined correctly"
  echo "This environment variable is needed to run this program"
  exit 1
fi

#Find the configuration directory: GEOSERVER_DATA_DIR
if [ -z $GEOSERVER_DATA_DIR ]; then
    if [ -r "$GEOSERVER_HOME"/data_dir ]; then
        export GEOSERVER_DATA_DIR="$GEOSERVER_HOME"/data_dir
    else
        echo "No GEOSERVER_DATA_DIR found, using application defaults"
	      GEOSERVER_DATA_DIR=""
    fi
fi

cd "$GEOSERVER_HOME"

if [ -z $MARLIN_JAR]; then
  # Java version detection from
  # https://stackoverflow.com/questions/7334754/correct-way-to-check-java-version-from-bash-script
  IFS=$'\n'
  # remove \r for Cygwin
  lines=$("$java_cmd" -Xms32M -Xmx32M -version 2>&1 | tr '\r' '\n')
  if [ -z $java_cmd ]; then
    result=no_java
  else
    for line in $lines; do
      if [ (-z $result) && ($line = *"version \""*) ]; then
        ver=$(echo $line | sed -e 's/.*version "\(.*\)"\(.*\)/\1/; 1q')
        if [ $ver = "1."* ]; then
          result=$(echo $ver | sed -e 's/1\.\([0-9]*\)\(.*\)/\1/; 1q')
        else
          result=$(echo $ver | sed -e 's/\([0-9]*\)\(.*\)/\1/; 1q')
        fi
      fi
    done
  fi

  if [ result -eq 8 ]; then
    export MARLIN_JAR=`find \`pwd\`/webapps -name "marlin*.jar" | head -1`
    export MARLIN_ENABLER="-Xbootclasspath/a:$MARLIN_JAR -Dsun.java2d.renderer=org.marlin.pisces.MarlinRenderingEngine"
  fi
fi

echo "GEOSERVER DATA DIR is $GEOSERVER_DATA_DIR"
#added headless to true by default, if this messes anyone up let the list
#know and we can change it back, but it seems like it won't hurt -ch
exec "$_RUNJAVA" $JAVA_OPTS $MARLIN_ENABLER -DGEOSERVER_DATA_DIR="$GEOSERVER_DATA_DIR" -Djava.awt.headless=true -DSTOP.PORT=8079 -DSTOP.KEY=geoserver -jar start.jar 
