#server {
#    listen 80;
#    #resolver 114.114.114.114 8.8.8.8;
#    #resolver_timeout 1s;
#
#    error_log logs/nginx.log info;
#    #access_log logs/ac cess.log main;
#    
#    location / {
#      root   /usr/secloud/html/Cardiocloud_http/dist;
#      index  index.html index.htm;
#      add_header  Access-Control-Allow-Origin "*";
#      
#    }
#
#    error_page   500 502 503 504  /50x.html;
#    location = /50x.html {
#      root   html;
#      add_header  Access-Control-Allow-Origin "*";
#    }
#    gzip on;
#    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
#    gzip_proxied any;
#    gzip_comp_level 6;
#    gzip_buffers 16 8k;
#    gzip_http_version 1.1;
#    gzip_vary on;
#}

server {
    listen 81;
    #resolver 114.114.114.114 8.8.8.8;
    #resolver_timeout 1s;

    error_log logs/nginx.log info;
    #access_log logs/ac cess.log main;
    
    location / {
      root   /usr/secloud/html/notify/dist;
      index  index.html index.htm;
      add_header  Access-Control-Allow-Origin "*";
      
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
      root   html;
      add_header  Access-Control-Allow-Origin "*";
    }
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_vary on;
}
#server {
#    listen 81;
#  	 location / {
#  	  root   /usr/secloud/html/dicomweb_http/dist;
##      root   /usr/secloud/html/notify/dist;
#      index  index.html index.htm;
#      
#    }
#    
#}

server {
    listen 82;
    #resolver 114.114.114.114 8.8.8.8;
    #resolver_timeout 1s;

    error_log logs/nginx.log info;
    #access_log logs/ac cess.log main;
    
    location / {
      root   /usr/secloud/html/test/dist;
      index  index.html index.htm;
      add_header  Access-Control-Allow-Origin "*";
     
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
      root   html;
      add_header  Access-Control-Allow-Origin "*";
    }
     gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_vary on;
}

server {
    listen 443 ssl;
    server_name peiheartmedical.com;

    ssl_certificate /usr/secloud/pxHeart-gateway/conf/peiheartmedical.com.pem;
    ssl_certificate_key /usr/secloud/pxHeart-gateway/conf/peiheartmedical.com.key;
    # SSL 配置，包括 SSL 协议和加密算法设置
    #ssl_session_cache    shared:SSL:5m;
    	ssl_session_timeout  5m;
     ssl_protocols TLSv1.2 TLSv1.3;
#    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5:!RC4:!DHE;
     ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384...';
     ssl_prefer_server_ciphers on;

 	ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4;
#    autoindex off;
    # report的静态文件目录配置
    location  / {
        root /usr/secloud/html/CardioCloud/dist;
        index index.html;
#       add_header 'Cross-Origin-Embedder-Policy' 'require-corp'; # 保留此头
        add_header 'Cross-Origin-Opener-Policy' 'same-origin';   # 保留此头
        # 在这里应用 CORS 控制
        if ($allowed_origin != "") {
            add_header 'Access-Control-Allow-Origin' $allowed_origin always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type' always;
            add_header 'Access-Control-Max-Age' 1728000 always;
            # add_header 'Access-Control-Allow-Credentials' 'true' always;
        }
        # 处理 OPTIONS 预检请求
        if ($request_method = 'OPTIONS') {
            if ($allowed_origin != "") {
                add_header 'Access-Control-Allow-Origin' $allowed_origin always;
                add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
                add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type' always;
                add_header 'Access-Control-Max-Age' 1728000 always;
                # add_header 'Access-Control-Allow-Credentials' 'true' always;
            }
            add_header 'Content-Length' 0;
            add_header 'Content-Type' 'text/plain charset=utf-8';
            return 204;
        }
    }

  
    # 默认首页配置


# # 后端服务的代理配置
    location /dicomweb {
        proxy_pass http://localhost:8082;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_redirect off;
         if ($allowed_origin != "") {
            add_header 'Access-Control-Allow-Origin' $allowed_origin always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type' always;
            add_header 'Access-Control-Max-Age' 1728000 always;
            # add_header 'Access-Control-Allow-Credentials' 'true' always;
        }
        # 处理 OPTIONS 预检请求
        if ($request_method = 'OPTIONS') {
            if ($allowed_origin != "") {
                add_header 'Access-Control-Allow-Origin' $allowed_origin always;
                add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
                add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type' always;
                add_header 'Access-Control-Max-Age' 1728000 always;
                # add_header 'Access-Control-Allow-Credentials' 'true' always;
            }
            add_header 'Content-Length' 0;
            add_header 'Content-Type' 'text/plain charset=utf-8';
            return 204;
        }
    }
#    # 后端服务的代理配置
   location /api/all {
        proxy_pass http://localhost:8082;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_redirect off;
         # 添加额外的配置，如需要跨域支持等
    add_header 'Access-Control-Allow-Origin' '*';
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
    add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
    add_header 'Access-Control-Max-Age' 1728000;
    }
      location /api/v1 {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_redirect off;
         # 添加额外的配置，如需要跨域支持等
    add_header 'Access-Control-Allow-Origin' '*';
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
    add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
    add_header 'Access-Control-Max-Age' 1728000;
    }

    location /static {
        proxy_pass http://localhost:84;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_redirect off;
#        autoindex off;
         # 添加额外的配置，如需要跨域支持等
    add_header 'Access-Control-Allow-Origin' '*';
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
    add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
    add_header 'Access-Control-Max-Age' 1728000;
    }
     gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_vary on;
}


server {
#    listen 443 ssl http2;
    listen 443 ssl;
#    http2 on;
#    listen [::]:443 ssl;
#    http2;
    server_name view.peiheartmedical.com;

    ssl_certificate /usr/secloud/pxHeart-gateway/conf/view.peiheartmedical.com.pem;
    ssl_certificate_key /usr/secloud/pxHeart-gateway/conf/view.peiheartmedical.com.key;
	
    # SSL 配置，包括 SSL 协议和加密算法设置
    #ssl_session_cache    shared:SSL:5m;
    ssl_session_timeout  5m;
     ssl_protocols TLSv1.2 TLSv1.3;
#    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5:!RC4:!DHE;
     ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384...';
     ssl_prefer_server_ciphers on;

 	ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4;
#	autoindex off;
    # report的静态文件目录配置
    location  / {
        root /usr/secloud/html/dicomweb/dist;
        index index.html;
         add_header 'Cross-Origin-Embedder-Policy' 'require-corp';
   	    add_header 'Cross-Origin-Opener-Policy' 'same-origin';
#   	     autoindex off;
    }


    # 默认首页配置


# # 后端服务的代理配置
    location /dicomweb {
        proxy_pass http://localhost:8082;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_redirect off;
    add_header 'Access-Control-Allow-Origin' '*';
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
    add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
    add_header 'Access-Control-Max-Age' 1728000;
    }
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_vary on;
}
