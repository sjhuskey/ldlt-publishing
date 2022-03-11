#!/bin/bash

FILES=$(git diff --name-only $BEFORE..$AFTER | grep "sources/.*\.xml")

convert() {
  echo "Converting $1"
  DIR=$(basename "$1" | sed 's/\.xml//')
  if [ ! -d "docs/$DIR" ]; then
    mkdir "docs/$DIR"
  fi
  echo "Output to docs/$DIR/index.html"
  saxon -s:"$1" -xsl:xslt/publish.xsl -o:"docs/$DIR/index.html"
}

for f in $FILES
do
  echo "Processing file $f"
  convert "$f"
done  