PHP_VERSION="8.2"
PHP_OPCACHE_MEMORY="512"
LATEST_PHP_VERSION=""
dnf module list php -y
# Gets all available php versions from remi repo
DNF_PHP_MODULE_LIST=$(dnf module list php -y)
# Extract the latest version
CHECK_LATEST_PHP_VERSION=$(echo "$DNF_PHP_MODULE_LIST" | awk '{ print $2 }' | sort | grep 'remi' | tail -1 | cut -d '-' -f2)
if [ -z "$CHECK_LATEST_PHP_VERSION" ]
then
      echo "REMI repo is not installed"
      exit 1
fi

if [ $PHP_VERSION == "latest" ]
then
    PHP_VERSION=$CHECK_LATEST_PHP_VERSION
fi

CHECK_SELECTED_PHP_VERSION=$(echo "$DNF_PHP_MODULE_LIST" | awk '{ print $2 }' | sort | grep 'remi' | grep "$PHP_VERSION" | cut -d '-' -f2)


echo "Installing php version: $PHP_VERSION"
echo "Latest PHP Version Release: $CHECK_LATEST_PHP_VERSION"
if [ -z "$CHECK_SELECTED_PHP_VERSION" ]
then
      echo "PHP Version "$PHP_VERSION" are not exists in Repository!"
      exit 1
fi
dnf module enable php:remi-$PHP_VERSION -y
dnf module install php:remi-$PHP_VERSION -y
dnf install -y php php-mysql php-redis php-opcache php-intl php-imagick php-zip
php -v

PHPINI_FILE=$(php -i | grep 'Loaded Configuration File' | cut -d '>' -f2 | awk '{$1=$1};1')
PHP_MODULES_CONFS_DIR=$(php -i | grep 'additional .ini files' | cut -d '>' -f2 | awk '{$1=$1};1')
echo "PHP INI File is located at: $PHPINI_FILE"
echo "PHP Modules Dir: $PHP_MODULES_CONFS_DIR"


# Configure & Secure PHP
sed -i 's/disable_functions =/disable_functions = show_source, system, shell_exec, passthru, exec, phpinfo, popen, proc_open, ini_set/g' $PHPINI_FILE
sed -i 's/expose_php = On/expose_php = Off/g' $PHPINI_FILE
sed -i 's/short_open_tag = Off/short_open_tag = On/g' $PHPINI_FILE

# Configure OPCache
sed -i 's/opcache.enable_cli=1/opcache.enable_cli=0/g' /etc/php.d/10-opcache.ini
sed -i "s/;opcache.memory_consumption=128/opcache.memory_consumption=$PHP_OPCACHE_MEMORY/g" /etc/php.d/10-opcache.ini
sed -i 's/opcache.enable_cli=1/opcache.enable_cli=0/g' /etc/php.d/10-opcache.ini
