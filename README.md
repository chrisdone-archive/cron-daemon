# cron-daemon

An easy way to make background services on Linux or OS X

Using cron, run your program like this:

    * * * * * /path/to/cron-daemon \
       --program /path/to/foo \
       --pid /tmp/foo.pid \
       --log /tmp/foo.log \
       --stdout /tmp/foo.stdout.log \
       --stderr /tmp/foo.stderr.log \
       -e PORT=2018 \
       --pwd /opt/foo \
       -- some arguments for foo

The program will be started after one minute. Every minute, cron will
run `cron-daemon` which will check whether the process is running. If
it is, it does nothing. If not, it runs it and writes its process ID
to `foo.pid`.

Because it's cron, it will ensure the program is running regularly,
and also persist through system restarts or logout.
