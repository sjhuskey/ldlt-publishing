#!/bin/bash

convert() {
  echo $1
  DIR=$(basename $1 | sed 's/\.xml//')
  if [ ! -d "pub/$DIR" ]
    mkdir "pub/$DIR"
  fi
  saxon -s:"$1" -xsl:xslt/publish.xsl -o:"pub/$DIR/index.html"
}

while (( "$#" )); do
  convert $1
  shift
done  