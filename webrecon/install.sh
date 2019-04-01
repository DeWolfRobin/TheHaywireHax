apt install npm
npm install -g notify-cli
notify -r {key}
git clone https://github.com/nahamsec/bbht.git
chmod +x bbht/install.sh
./bbht/install.sh
git submodule update --init --recursive

pip install emailprotectionslib
