#!/bin/bash
 
NEW_USERS="users.txt"

#Users.txt Input format: USER PASSWORD GROUP HOME_BASE ALLOWLOGIN
#Example entries for users.txt file:
#username somepass somegroup /home/ default
#username2 s0m3p@s5 somegroup /home/ nologin

 
cat ${NEW_USERS} | \
 while read USER PASSWORD GROUP HOME_BASE ALLOWLOGIN
 do
  echo Adding ${USER} to Group ${GROUP}, with pw: ${PASSWORD}, Homedir: ${HOME_BASE}${USER}
  useradd -g ${GROUP} -p ${PASSWORD} -m -d ${HOME_BASE}${USER} ${USER}
  echo Updating password 
  echo -e "${PASSWORD}\n${PASSWORD}" | (passwd --stdin $USER)

  if [ "${ALLOWLOGIN}" == "nologin" ];
    echo Removing shell access for user ${USER}
    usermod -s /sbin/nologin ${USER}
   else
    echo Granted ${ALLOWLOGIN} shell access login to user ${USER}    
  fi

 done
 
