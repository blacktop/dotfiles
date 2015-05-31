#!/usr/bin/env bash

apm install --packages-file -c my-packages.txt

mv .atom/config.cson ~/.atom/
mv .atom/toolbar.json ~/.atom/
