#!/bin/sh

# Edit this script to set up any gateways you like.

while test \! -e /tmp/chaos_stream; do
    sleep 1
done

./gw 95 SUPDUP 3150
