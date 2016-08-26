FROM lucee/lucee4:4.5.2-t8.0.36
COPY docker/dummysite /var/www
COPY docker/resources/server.xml /usr/local/tomcat/conf/server.xml
COPY docker/resources/web.xml /usr/local/tomcat/conf/web.xml
COPY docker/resources/setenv.sh /usr/local/tomcat/bin/setenv.sh
COPY docker/resources/lucee-server.xml /opt/lucee/server/lucee-server/context/lucee-server.xml
COPY artifacts/build.zip temp.zip
RUN mkdir /opt/preside && \
	unzip temp -d /opt/preside/ && \
	rm -f temp.zip && \
	wget http://urlrewritefilter.googlecode.com/files/urlrewritefilter-4.0.3.jar -O /usr/local/tomcat/lib/urlrewritefilter-4.0.3.jar
