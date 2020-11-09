From nginx:alpine
#RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories 
RUN apk add --update --no-cache git bash bind=9.16.6-r0 
RUN touch /start.sh
RUN git config --global user.name scjtqs && git config --global user.email scjtqs@qq.com
RUN echo "cd /usr/share/nginx/html && git fetch --all && git reset --hard origin/master && git pull -f">>/start.sh
RUN chmod 777 /start.sh
RUN rm -rf /usr/share/nginx/html
RUN echo "0 */2 * * * /start.sh">>/var/spool/cron/crontabs/root
RUN sed -i "s/404\.html/index\.html}/g" /etc/nginx/conf.d/default.conf
RUN touch /crond.sh
RUN echo "crond && nginx -g 'daemon off;'">>/crond.sh
RUN chmod 777 /crond.sh
EXPOSE 443
EXPOSE 80
COPY bind /etc/bind/
COPY entrypoint.sh /entrypoint.sh
RUN mkdir -p /var/cache/bind && \
    chmod -R 777 /var/cache/bind && \
    chmod +x /entrypoint.sh && \
    chmod 644 \
      /etc/bind/named.conf /etc/bind/named.conf.default-zones /etc/bind/named.conf.options \
      /etc/bind/any.zone
RUN git clone --depth 1 https://github.com/zerofo/zerofo.github.io.git /usr/share/nginx/html
RUN sed -i "5a <script>if((document.location.pathname!='/index.html')&&(document.location.pathname != '/')){window.location.href='http://'+document.location.host;}</script>" /usr/share/nginx/html/index.html
EXPOSE 53/udp 53/tcp
RUN echo -e '/bin/bash /entrypoint.sh\n/bin/bash /crond.sh;' > /begin.sh
ENTRYPOINT ["/bin/bash","/begin.sh"]

