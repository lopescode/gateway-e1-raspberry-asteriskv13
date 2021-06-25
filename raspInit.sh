#!/bin/sh

###############################################
cd /usr/src/gateway-e1-raspberry-asteriskv13/ #
###############################################

# Configurando alias no bash
echo "Configurando alias no bash"
echo "alias 'll=ls -la'" >> ~/.bashrc

# Configurando rede interna
echo "Configurando rede interna"
sudo mv ./interfaces /etc/network/interfaces

# Configurando servidor DNS
echo "Configurando servidor DNS"
sudo mv ./resolv.conf /etc/resolv.conf

# Configurando as rotas de rede
echo "Configurando as rotas de rede"
sudo mv ./routes /etc/init.d/routes

# Configurando o rc.local
echo "Configurando o rc.local"
sudo mv ./rc.local /etc/rc.local

# Reiniciando o serviço de rede
echo "Reiniciando o serviço de rotas e ssh"
sudo chmod 755 /etc/init.d/routes
sudo /etc/init.d/routes
sudo /etc/init.d/ssh restart

# Instalando pacotes do Linux para a instalação do asterisk
echo "Instalando pacotes do Linux para a instalação do asterisk"
sudo apt install ssh make vim build-essential git-core subversion libjansson-dev libsqlite3-dev autoconf automake libxml2-dev libncurses5-dev libtool uuid-dev uuid dh-autoreconf -y

##############
cd /usr/src/ #
##############

# Baixando o asterisk v13
echo "Baixando o asterisk v13"
sudo wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-13-current.tar.gz

# Descompactando o asterisk v13
echo "Descompactando o asterisk v13"
sudo tar -zxvf asterisk-13-current.tar.gz

# Apagando o arquivo compactado do asterisk v13
echo "Apagando o arquivo compactado do asterisk v13"
sudo rm -rf asterisk-13-current.tar.gz

# Localizando o diretorio do asterisk v13
echo "Localizando o diretorio do asterisk v13"
asterisk=$(find . -name "asterisk-13.*")

##############
cd $asterisk #
##############

# Configurando o asterisk v13
echo "Configurando o asterisk v13"
sudo ./contrib/scripts/install_prereq install
sudo ./bootstrap.sh
sudo ./configure
sudo make && make install
sudo make samples
sudo make config

##############
cd /usr/src/ #
##############

# Baixando o codec g729
echo "Baixando o codec g729"
sudo wget http://download-mirror.savannah.gnu.org/releases/linphone/plugins/sources/bcg729-1.0.0.tar.gz

# Descompactando o codec g729
echo "Descompactando o codec g729"
sudo tar -xzf bcg729-1.0.0.tar.gz

#################
cd bcg729-1.0.0 #
#################

# Configurando o codec g729
echo "Configurando o codec g729"
sudo ./configure --libdir=/lib
sudo make && make install

#############
cd /usr/src #
#############

# Baixando o codec g72x
sudo wget http://asterisk.hosting.lv/src/asterisk-g72x-1.4.tar.bz2

# Descompactando o codec g729
echo "Descompactando o codec g72x"
sudo tar -xjf asterisk-g72x-1.4.tar.bz2

######################
cd asterisk-g72x-1.4 #
######################

# Configurando o codec g72x
echo "Configurando o codec g72x"
sudo ./autogen.sh
sudo ./configure CFLAGS='-march=armv6' --with-asterisk130 --with-bcg729 --with-asterisk-includes=/usr/include
sudo make && make install
sudo chmod +x /usr/lib/asterisk/modules/codec_g729.so

# Apagando os arquivos compactados dos codecs
echo "Apagando os arquivos compactados dos codecs"
sudo rm -rf bcg729-1.0.0.tar.gz
sudo rm -rf asterisk-g72x-1.4.tar.bz2

# Iniciando o serviço do asterisk e verificando o status
echo "Iniciando o serviço do asterisk"
sudo /etc/init.d/asterisk start
sudo /etc/init.d/asterisk status

# Realizando backup dos arquivos sip.conf e extensions.conf do asterisk
echo "Realizando backup dos arquivos sip.conf e extension.conf do asterisk"
sudo mv /etc/asterisk/sip.conf /etc/asterisk/sip.conf.bkp
sudo mv /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.bkp

##############################################
cd /usr/src/gateway-e1-raspberry-asteriskv13 #
##############################################

# Movendo os arquivos configurados do sip.conf e extensions.conf
echo "Movendo os arquivos configurados do sip.conf e extensions.conf"
sudo mkdir -p /etc/asterisk/krolik
sudo mv ./sip-peers.conf /etc/asterisk/krolik
sudo mv ./sip-trunk.conf /etc/asterisk/krolik
sudo mv ./sip.conf /etc/asterisk/sip.conf
sudo mv ./extensions.conf /etc/asterisk/extensions.conf

# Aplicando as configurações realizadas
echo "Aplicando as configurações realizadas"
sudo asterisk -rx 'sip reload'
sudo asterisk -rx 'dialplan reload'

# Verificando peers conectados
echo "Verificando peers conectados"
sudo asterisk -rx 'sip show peers'
