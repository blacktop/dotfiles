#!/bin/bash

sudo apt-get install --reinstall ca-certificates

sudo -E add-apt-repository -y ppa:webupd8team/java

sudo apt-get update \
  && sudo apt-get -y install oracle-java8-installer
