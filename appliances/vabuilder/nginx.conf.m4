user nginx nginx;
worker_processes 1;

error_log /var/log/nginx/error_log info;

events {
	worker_connections 1024;
	use epoll;
}

http {
	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	log_format main
		'$remote_addr - $remote_user [$time_local] '
		'"$request" $status $bytes_sent '
		'"$http_referer" "$http_user_agent" '
		'"$gzip_ratio"';

	client_header_timeout 10m;
	client_body_timeout 10m;
	send_timeout 10m;

	connection_pool_size 256;
	client_header_buffer_size 1k;
	large_client_header_buffers 4 2k;
	request_pool_size 4k;

	gzip on;
	gzip_min_length 1100;
	gzip_buffers 4 8k;
	gzip_types text/plain;

	output_buffers 1 32k;
	postpone_output 1460;

	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;

	keepalive_timeout 75 20;

	ignore_invalid_headers on;

	index index.html;

	server {
		listen 0.0.0.0;
		server_name HOSTNAME;

		access_log /var/log/nginx/HOSTNAME.access_log main;
		error_log /var/log/nginx/HOSTNAME.error_log info;

		root /var/www/localhost/htdocs;

        location /images/ {
            alias VABUILDER_HOME/images/;
            fancyindex on;
            fancyindex_exact_size off;
            fancyindex_localtime on;
        }

	}

	# SSL example
	#server {
	#	listen 127.0.0.1:443;
	#	server_name HOSTNAME;

	#	ssl on;
	#	ssl_certificate /etc/ssl/nginx/nginx.pem;
	#	ssl_certificate_key /etc/ssl/nginx/nginx.key;

	#	access_log /var/log/nginx/HOSTNAME.ssl_access_log main;
	#	error_log /var/log/nginx/HOSTNAME.ssl_error_log info;

	#	root /var/www/localhost/htdocs;
	#}
}
