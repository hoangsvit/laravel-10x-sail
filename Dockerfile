# Sử dụng ảnh cơ sở PHP
FROM richarvey/nginx-php-fpm:3.1.6

# Cài đặt các gói cần thiết
RUN apt-get update && apt-get install -y \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    nano

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
COPY ./docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

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
