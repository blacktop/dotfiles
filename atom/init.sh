#!/usr/bin/env bash

apm install --packages-file -c packages.txt

mv .atom/config.cson ~/.atom/
mv .atom/toolbar.cson ~/.atom/
