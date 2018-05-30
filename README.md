# cron-daemon

An easy way to make background services on Linux or OS X

Using cron, run your program like this:

``` shell
* * * * * /path/to/cron-daemon \
   --program /path/to/foo \
   --pid /tmp/foo.pid \
   --log /tmp/foo.log \
   --stdout /tmp/foo.stdout.log \
   --stderr /tmp/foo.stderr.log \
   -e PORT=2018 \ # optional, to pass environment variables
   --pwd /opt/foo \
   -- some arguments for foo # optional
```

The program will be started after one minute. Every minute, cron will
run `cron-daemon` which will check whether the process is running. If
it is, it does nothing. If not, it runs it and writes its process ID
to `foo.pid`.

Because it's cron, it will ensure the program is running regularly,
and also persist through system restarts or logout.

# Help text

Run `--help`:

    cron-daemon - Run a program as a daemon with cron

    Usage: cron-daemon --program PROGRAM --pid FILEPATH --log FILEPATH
                       --stderr FILEPATH --stdout FILEPATH [-e|--env NAME=value]
                       --pwd DIR [ARGUMENT]
      Run a program as a daemon with cron

    Available options:
      --program PROGRAM        Run this program
      --pid FILEPATH           Write the process ID to this file
      --log FILEPATH           Log file
      --stderr FILEPATH        Process stderr file
      --stdout FILEPATH        Process stdout file
      -e,--env NAME=value      Environment variable
      --pwd DIR                Working directory
      ARGUMENT                 Argument for the child process
      -h,--help                Show this help text
