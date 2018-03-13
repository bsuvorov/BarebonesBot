#!/bin/sh
git stash && ./refetch.sh  && git stash pop && vapor build && ./restart.sh
