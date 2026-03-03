#!/bin/bash

rsync -rtva --progress /Users/rdircio/uExplorer/ root@hoshibb.local:/opt/uExplorer/
ssh root@hoshibb.local "cd /opt/uExplorer && ./uExplorer.ksh"