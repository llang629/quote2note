# run 'sudo bash install.sh'
# recipe for AWS Ubuntu 12.04

apt-get update
apt-get upgrade

# folder for .mid .wav .mp3 files
echo "export Q2N_FOLDER=./public" >>.profile
. .profile


# install ruby version manager and ruby
# see ‘rvm list remote’ for current binaries
\curl -L https://get.rvm.io | bash -s stable --ruby=ruby-2.0.0-p353
gem install rack rake sinatra  --no-document
gem install daemon_controller  --no-document #required by passenger
gem install pony trollop midilib unimidi --no-document #required by application


# install Phusion Passenger
# see http://www.modrails.com/documentation/Users%20guide%20Standalone.html#install_on_debian_ubuntu
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
sudo apt-get install apt-transport-https ca-certificates

echo Phusion Passenger repository configuring for Ubuntu 12.04
FILE="/etc/apt/sources.list.d/passenger.list"
sudo cat <<EOM >$FILE
##### !!!! Only add ONE of these lines, not all of them !!!! #####
# Ubuntu 13.10
# deb https://oss-binaries.phusionpassenger.com/apt/passenger saucy main
# Ubuntu 12.04
deb https://oss-binaries.phusionpassenger.com/apt/passenger precise main
# Ubuntu 10.04
# deb https://oss-binaries.phusionpassenger.com/apt/passenger lucid main
# Debian 7
# deb https://oss-binaries.phusionpassenger.com/apt/passenger wheezy main
# Debian 6
# deb https://oss-binaries.phusionpassenger.com/apt/passenger squeeze main
EOM

sudo chown root: /etc/apt/sources.list.d/passenger.list
sudo chmod 600 /etc/apt/sources.list.d/passenger.list
sudo apt-get update
sudo apt-get install passenger


# see http://wootangent.net/2010/11/converting-midi-to-wav-or-mp3-the-easy-way/
# install fluidsynth for .mid to .wav
sudo apt-get install fluidsynth fluid-soundfont-gm
# install lame for .wav to .mp3
sudo apt-get install lame

# install git
sudo apt-get install git
git config --global push.default simple

# install application
mkdir quote2note
cd quote2note
git clone https://github.com/llang629/quote2note.git

# start application
rvmsudo passenger start --port 80 --user=ubuntu


