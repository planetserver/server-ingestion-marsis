#!/bin/bash

psql marsisdb 
psql -d marsisdb -c "CREATE EXTENSION postgis;"
psql -d marsisdb -c "CREATE EXTENSION postgis_topology;"

