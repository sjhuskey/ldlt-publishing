#!/bin/bash

convert() {
  echo $1
  DIR=$(basename $1 | sed 's/\.xml//')
  if [ ! -d "pub/$DIR" ]
    mkdir "pub/$DIR"
  fi
  saxon -s:"$1" -xsl:xslt/publish.xsl -o:"pub/$DIR/index.html"

  OUT1=$(echo $1 | sed 's/\([[:digit:]]*\).docx/\1.xml/')
  OUT2=$(echo $OUT1 | sed "s/docx\//articles\//")
  if [ ! -f "$OUT2" ]; then
    /opt/stylesheets/bin/docxtotei $f "$OUT1"
    saxon -s:"$OUT1" -xsl:xslt/process-$1.xsl -o:"$OUT2"
    if [ -f "$OUT1" ]; then
      rm "$OUT1"
    fi
  fi
}

while (( "$#" )); do
  convert $1
  shift
done  