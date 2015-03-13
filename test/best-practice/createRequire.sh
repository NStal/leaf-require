#!/bin/bash

read version < ./version
version=$((version + 1))
echo $version > ./version

leafjs-require ./js -r "./js" --set-version "0.0.0."$version -o ./require.json --excludes ./js/init.js
