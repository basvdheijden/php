# Base PHP container

- INI files can be found in `/usr/local/etc/php/`
- Kill `php-fpm` inside the container by running: `kill -USR2 1`

- Use the following environment variables to your liking:

```
PHP_UPLOAD_MAX_FILESIZE
PHP_MEMORY_LIMIT
XDEBUG_MODE
XDEBUG_HOST
```
