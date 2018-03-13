#!/bin/sh
./refetch.sh && vapor build && ./restart.sh $1
