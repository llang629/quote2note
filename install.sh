#!/bin/bash 
# install for AWS Ubuntu 14.04.2 LTS (GNU/Linux 3.13.0-44-generic x86_64)
# retrieve and run using these commands…
# wget https://raw.githubusercontent.com/llang629/quote2note/master/install.sh
# bash install.sh

sudo apt-get -y update
sudo apt-get -y upgrade

# directory for application .mid .wav .mp3 files
echo export Q2N_DIR=./public/cache >>.profile
# fix for Passenger security warning
echo export rvmsudo_secure_path=0 >>.profile
. .profile
# only effective during this script run
# after terminating Passenger web server, either logout/login or repeat ". .profile"


# install sendmail to support Pony.mail
sudo apt-get -y install sendmail-bin


# RVM 1.26.0 introduced signed releases and automated check of signatures when GPG software found.
# import the Michal Papis mpapis public key, verify with https://rvm.io/mpapis.asc or https://keybase.io/mpapis
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
# if that fails, try
# command curl -sSL https://rvm.io/mpapis.asc | gpg --import -

# install Ruby Version Manager and Ruby
\curl -L https://get.rvm.io | bash -s stable

# Load RVM into a shell session *as a function*
if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
# First try to load from a user install
source "$HOME/.rvm/scripts/rvm"
elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
# Then try to load from a root install
source "/usr/local/rvm/scripts/rvm"
else
printf "ERROR: An RVM installation was not found.\n"
fi

# install ruby
rvm install 2.0

# install gems
gem install rack rake sinatra  --no-document
gem install daemon_controller  --no-document #required by passenger
gem install pony trollop midilib unimidi --no-document #required by application
# updates may require
# gem update
# and bundle install


# install Phusion Passenger
# see http://www.modrails.com/documentation/Users%20guide%20Standalone.html#install_on_debian_ubuntu
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
sudo apt-get -y install apt-transport-https ca-certificates

echo Phusion Passenger repository configuring for Ubuntu 12.04
FILE="/etc/apt/sources.list.d/passenger.list"
sudo bash -c "cat <<EOM >$FILE
##### !!!! Only add ONE of these lines, not all of them !!!! #####
# Ubuntu 14.04
deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main
# Ubuntu 12.04
# deb https://oss-binaries.phusionpassenger.com/apt/passenger precise main
# Ubuntu 10.04
# deb https://oss-binaries.phusionpassenger.com/apt/passenger lucid main
# Debian 7
# deb https://oss-binaries.phusionpassenger.com/apt/passenger wheezy main
# Debian 6
# deb https://oss-binaries.phusionpassenger.com/apt/passenger squeeze main
EOM"

sudo chown root: /etc/apt/sources.list.d/passenger.list
sudo chmod 600 /etc/apt/sources.list.d/passenger.list
sudo apt-get -y update
sudo apt-get -y install passenger


# see http://wootangent.net/2010/11/converting-midi-to-wav-or-mp3-the-easy-way/
# install fluidsynth for .mid to .wav
sudo apt-get -y install fluidsynth fluid-soundfont-gm
# install lame for .wav to .mp3
sudo apt-get -y install lame


# install git
sudo apt-get -y install git


# install application
git clone https://github.com/llang629/quote2note.git
cd quote2note


# directory for locks from Passenger
mkdir tmp
mkdir pids

# directory for logs from Passenger, New Relic (requires chown and chmod), and clearcache.sh
mkdir log
sudo chown root:root log
sudo chmod 777 log


# start application
screen rvmsudo -E passenger start --port 80 --user=ubuntu
