FROM osrm/osrm-frontend

RUN npm cache clean -f && \
    npm update && \
    npm install npm@latest -g && \
    npm install && \
    npm -version