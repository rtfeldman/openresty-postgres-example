.PHONY: all clean 

all:
	@/usr/local/openresty/nginx/sbin/nginx -s stop; /usr/local/openresty/nginx/sbin/nginx && echo "Build succeeded!"

clean:
	/usr/local/openresty/nginx/sbin/nginx -s stop;
