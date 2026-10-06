#!/bin/sh
set -eu

node dist/database/run-migrations.js

exec node dist/main
