#!/bin/sh

# NOTE: build ornot
cc -O3 -march=native -fms-extensions build.c -o build
./build
