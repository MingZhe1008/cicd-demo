FROM nginx:stable-alpine

ARG GIT_COMMIT=manual
ARG BUILD_NUMBER=manual
ARG BUILD_TIME=unknown

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY site/ /usr/share/nginx/html/

RUN printf '{"commit":"%s","build":"%s","builtAt":"%s"}\n' "$GIT_COMMIT" "$BUILD_NUMBER" "$BUILD_TIME" > /usr/share/nginx/html/build.json \
    && find /usr/share/nginx/html -type d -exec chmod 755 {} \; \
    && find /usr/share/nginx/html -type f -exec chmod 644 {} \;

EXPOSE 80