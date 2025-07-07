# log-cleaner : a finished project written during my 2024-25 devops training

A log cleaning utility written in bash : remove log files by size or by access date.

Target directory : $HOME/logs (coz var/log too complicated to handle correctly for me) 

First exec without any flags : installs the app and adds an entry in crontab. The installation process can be configured with selected options in the following file : $HOME/.cleaner.conf  (available options : select the log directory, min file size and last access) 

Exec with the -u flag : uninstalls the app and removes the crontab entry.

Exec with the -s (s for stash) : moves the filtered log files $HOME/logs dans $HOME/logs/stash. A time related prefix (number of secs since jan 1, 1970) is added to avoid collisions between files with the same name.

Exec with the -h flag to get some more info.
