#!/bin/bash

convert() {
  echo "Converting $1"
  DIR=$(basename "$1" | sed 's/\.xml//')
  if [ ! -d "pub/$DIR" ]; then
    mkdir "pub/$DIR"
  fi
  saxon -s:"$1" -xsl:xslt/publish.xsl -o:"pub/$DIR/index.html"
}

while (( "$FILES" )); do
  echo "Processing file $1"
  if [ -n "$($1 | grep "sources/.*\.xml")" ]; then
    convert "$1"
  fi
  shift
done  