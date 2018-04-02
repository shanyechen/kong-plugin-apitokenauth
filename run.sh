#!/bin/sh
set -e


kong start && tail -f /usr/local/kong/logs/error.log