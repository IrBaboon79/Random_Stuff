#!/bin/bash
 
SET_SRV="services.txt"
 
cat ${SET_SRV} | \
 while read SRV STATE
 do
  echo Disabling Autostart and Stopping Service ${SRV}
   chkconfig ${SRV} off
   service ${SRV} stop
 done
 
