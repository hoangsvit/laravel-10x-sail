# Sử dụng ảnh cơ sở PHP
FROM richarvey/nginx-php-fpm:3.1.6

# Cài đặt các gói cần thiết
RUN apt-get update \
    && apt-get install -y gnupg gosu curl ca-certificates zip unzip git supervisor sqlite3 libcap2-bin libpng-dev python2 dnsutils librsvg2-bin \
    && curl -sS 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c' | gpg --dearmor | tee /etc/apt/keyrings/ppa_ondrej_php.gpg > /dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/ppa_ondrej_php.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu jammy main" > /etc/apt/sources.list.d/ppa_ondrej_php.list \
    && apt-get update \
    && apt-get install -y php8.2-cli php8.2-dev \
       php8.2-pgsql php8.2-sqlite3 php8.2-gd php8.2-imagick \
       php8.2-curl \
       php8.2-imap php8.2-mysql php8.2-mbstring \
       php8.2-xml php8.2-zip php8.2-bcmath php8.2-soap \
       php8.2-intl php8.2-readline \
       php8.2-ldap \
       php8.2-msgpack php8.2-igbinary php8.2-redis php8.2-swoole \
       php8.2-memcached php8.2-pcov php8.2-xdebug \
    && curl -sLS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer \
    && curl -sLS https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /etc/apt/keyrings/yarn.gpg >/dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
    && curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/keyrings/pgdg.gpg >/dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/pgdg.gpg] http://apt.postgresql.org/pub/repos/apt jammy-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y yarn \
    && apt-get install -y mysql-client \
    && apt-get install -y postgresql-client-$POSTGRES_VERSION \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Cài đặt composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Cài đặt Node.js và npm
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs

# Cài đặt các phần mở rộng PHP cần thiết
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Đặt thư mục làm việc của PHP trong container
WORKDIR /var/www/html

# Sao chép tệp composer.lock và composer.json vào container
COPY composer.lock composer.json ./

# Cài đặt các gói PHP từ composer
RUN composer install --no-scripts --no-autoloader

# Sao chép toàn bộ mã nguồn Laravel vào container
COPY . .

# Tạo file .env từ mẫu .env.example
RUN cp .env.example .env

# Tạo khóa ứng dụng Laravel
RUN php artisan key:generate

# Cấu hình Nginx
COPY ./docker/nginx/default.conf /etc/nginx/conf.d/default.conf

# Xóa tệp mặc định của Nginx
RUN rm /etc/nginx/sites-enabled/default

# Cài đặt supervisor cho quản lý tiến trình
RUN apt-get install -y supervisor
COPY ./docker/8.2/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Thiết lập quyền và sở hữu cho các tệp Laravel
RUN chown -R www-data:www-data \
    /var/www/html/storage \
    /var/www/html/bootstrap/cache

# Tạo các tệp log cần thiết cho Nginx và PHP-FPM
RUN touch /var/log/nginx/access.log \
    && touch /var/log/nginx/error.log \
    && touch /var/log/php-fpm.log

# Mở cổng 80 để truy cập ứng dụng Laravel
EXPOSE 80

# Bật các dịch vụ Nginx và supervisor khi container chạy
CMD service nginx start && service supervisor start && php-fpm
