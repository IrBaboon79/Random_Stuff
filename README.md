Collection of Random Scripts

1. create_users.sh : easy bulk user creation from simple txt. Should be portable but only tested on CentOS 5.x.

2. disable_services.sh : easy bulk service disabling 
Should be portable but only tested on CentOS 5.x., note: invokes chkconfig, not suited for systemd distros.

3. testPoster_v0.42.ps1 : 
Parses a TVA.XML, extracts all mediaURI links and checks if the file exists on a given server using HTTP/HEAD, can also download the file if needed. Simple report output, helps to validate out-of-synch poster-servers.
