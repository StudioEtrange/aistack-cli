# runtime python


## python package tiktoken

* installed with pip or uv, there is existing prebuilt wheel. But the last compatible version for glibc 2.17 (RHEL/Centos 7) version avaiblable is tiktoken 0.11.0 https://pypi.org/project/tiktoken/0.11.0/
* tiktoken needs rust to compile source which might be a problem
* aistack integrations affected : sktor, ciss
  
## python package numpy

* installed with pip or uv, there is existing prebuilt wheel. But the last compatible version for glibc 2.17 (RHEL/Centos 7) version avaiblable is numpy 2.26 
* aistack integrations affected : sktors