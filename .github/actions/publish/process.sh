#!/bin/bash

convert() {
  echo $1
  DIR=$(basename $1 | sed 's/\.xml//')
  if [ ! -d "pub/$DIR" ]; then
    mkdir "pub/$DIR"
  fi
  saxon -s:"$1" -xsl:xslt/publish.xsl -o:"pub/$DIR/index.html"
}

while (( "$#" )); do
  echo "Processing file $1"
  convert $1
  shift
done  