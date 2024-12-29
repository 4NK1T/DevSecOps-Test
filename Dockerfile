# Use the official PHP image with Apache
FROM php:8.1-apache

# Copy application files to the web server root
COPY . /var/www/html

# Set permissions for the web server
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Expose port 80 for external access
EXPOSE 80

# Start the Apache server
CMD ["apache2-foreground"]
