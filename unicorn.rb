@dir = "/usr/share/nginx/www/g.morishin.me/"

worker_processes 1
working_directory @dir

timeout 30
listen "/tmp/.unicorn.sock"

pid "/tmp/unicorn.pid"

stderr_path "#{@dir}log/unicorn.stderr.log"
stdout_path "#{@dir}log/unicorn.stdout.log"