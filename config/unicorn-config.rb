listen 8080
worker_processes 4
pid "log/unicorn.pid"
stderr_path "log/unicorn.err"
stdout_path "log/unicorn.log"
