
# set -e

GITNAME="${GIT_NAME:-"ci"}"
GITEMAIL="${GIT_EMAIL:-"ci@me"}"

git config --global user.name $GITNAME
git config --global user.email $GITEMAIL



# if [ "$TRAVIS_OS_NAME" = "linux" ]; then 
    # if [ ! test $(wine --version) ]; then

    echo "Устанавливаю Wine"
    # add-apt-repository ppa:ubuntu-wine/ppa
    apt-get update
    apt-get install -y wine winetricks
   
    # fi
# fi
mkdir ./build

wget -O os.deb http://oscript.io/downloads/1_0_19/onescript-engine_1.0.19_all.deb
sudo dpkg -i *.deb; sudo apt install -f
rm os.deb
rm -R /tmp/gitsync/
wget -O ./gitsync.ospx $(curl -s https://api.github.com/repos/khorevaa/gitsync/releases/latest | grep 'gitsync-' | cut -d\" -f4)
# wget -O gitsync.ospx https://github.com/khorevaa/gitsync/releases/download/3.0.0-beta/ 
opm install opm; 
opm install 1testrunner; 
opm install 1bdd; 
opm install cli;
opm install -f ./gitsync.ospx -dest /tmp/; 

opm build -out ./build ./;
opm install -f ./build/$(ls -a ./build | grep ^preinstalled) -dest /tmp/gitsync/installed_plugins;

opm install; 
opm test; 

rm -R ./build
