# Nagios Powershell scripts

## Setup
You'll need a proxy host to run your Powershell commands (or they can be run directly from the server(s)).

I used Windows 2012 Core machines running NSClient++ to execute the scripts on remote machines. NSClient service needs to run as a user with permissions to invoke the commands in the script themselves. The benefit to this architecture is that you don't require clients on the remote machines themselves, nor do you need to store credentials anywhere within the scripts or arguements. 

NAGIOS executes the command against the proxy via check_nrpe, which invokes them against the remote Windows server specified in the parameters. Pass arguements according to preference, most are easily templatable using $HOSTNAME$ macro and a few sane defaults. 
