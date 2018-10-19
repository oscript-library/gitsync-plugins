
set -e

git config --global user.name $GITNAME
git config --global user.email $GITEMAIL

echo "Устанавливаю версию OScript <$OSCRIPT_VERSION>"
curl http://oscript.io/downloads/$OSCRIPT_VERSION/deb > oscript.deb 
dpkg -i oscript.deb 
rm -f oscript.deb

echo "Установка зависимостей тестирования"
opm install 1testrunner; 
opm install 1bdd;
opm install coverage;
opm update opm 

echo "Установка зависимостей"
opm install; 

echo "Подготовка к тестированию"
opm run install-gitsync;
opm run testing-build;

echo "Запуск тестирования пакета"
opm run coverage; 

