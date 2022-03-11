#!/bin/bash

FILES=$(git diff --name-only $BEFORE..$AFTER | grep "sources/.*\.xml")

convert() {
  echo "Converting $1"
  DIR=$(basename "$1" | sed 's/\.xml//')
  if [ ! -d "pub/$DIR" ]; then
    mkdir "pub/$DIR"
  fi
  saxon -s:"$1" -xsl:xslt/publish.xsl -o:"pub/$DIR/index.html"
}

for f in $FILES
do
  echo "Processing file $f"
  convert "$f"
  shift
done  