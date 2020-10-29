FROM pixl8/pixl8-build-utility-docker-image:v2.0.0
COPY entrypoint.sh /entrypoint.sh
COPY box.json /box.json
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]