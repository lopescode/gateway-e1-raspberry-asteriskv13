#!/bin/sh

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
echo "Reiniciando o serviço de rede, rotas e ssh"
/etc/init.d/networking restart
/etc/init.d/routes
/etc/init.d/ssh restart

# Instalando pacotes do Linux para a instalação do asterisk
echo "Instalando pacotes do Linux para a instalação do asterisk"
apt install ssh make vim build-essential git-core subversion libjansson-dev libsqlite3-dev autoconf automake libxml2-dev libncurses5-dev libtool uuid-dev uuid dh-autoreconf -y

# Asterisk v13

cd /usr/src/

echo "Baixando o asterisk v13"
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-13-current.tar.gz

echo "Descompactando o asterisk v13"
tar -zxvf asterisk-13-current.tar.gz

echo "Apagando o arquivo compactado do asterisk v13"
rm -rf asterisk-13-current.tar.gz

echo "Instalando e configurando o asterisk v13"
asterisk=$(find . -name "asterisk-13.*")
cd $asterisk
./contrib/scripts/install_prereq install
./bootstrap.sh
./configure
make && make install
make samples
make config

# Codec G729

cd /usr/src/

echo "Baixando o codec g729"
wget http://download-mirror.savannah.gnu.org/releases/linphone/plugins/sources/bcg729-1.0.0.tar.gz

echo "Descompactando o codec g729"
tar -xzf bcg729-1.0.0.tar.gz

echo "Instalando o codec g729"
cd bcg729-1.0.0

./configure --libdir=/lib
make && make install

echo "Baixando o codec g72x"
cd /usr/src
wget http://asterisk.hosting.lv/src/asterisk-g72x-1.4.tar.bz2

echo "Descompactando o codec g72x"
tar -xjf asterisk-g72x-1.4.tar.bz2

echo "Instalando o codec g72x"
cd asterisk-g72x-1.4
./autogen.sh
./configure CFLAGS='-march=armv6' --with-asterisk130 --with-bcg729 --with-asterisk-includes=/usr/include
make && make install
chmod +x /usr/lib/asterisk/modules/codec_g729.so

echo "Apagando os arquivos compactados dos codecs"
sudo rm -rf bcg729-1.0.0.tar.gz
sudo rm -rf asterisk-g72x-1.4.tar.bz2

echo "Iniciando o serviço do asterisk"
/etc/init.d/asterisk start

echo "Testando o serviço do asterisk"
/etc/init.d/asterisk status

echo "Renomeando sip.conf e extension.conf padrão do asterisk"
mv /etc/asterisk/sip.conf /etc/asterisk/sip.conf.bkp
mv /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.bkp

echo "Enviando arquivos para suas determinadas pastas"
mkdir -p /etc/asterisk/krolik
cd /usr/src/gateway-e1-raspberry-asteriskv13
mv ./sip-peers.conf /etc/asterisk/krolik
mv ./sip-trunk.conf /etc/asterisk/krolik
mv ./sip.conf /etc/asterisk/sip.conf
mv ./extensions.conf /etc/asterisk/extensions.conf

echo "Aplicando as configurações realizadas"
sudo asterisk -rx 'sip reload'
sudo asterisk -rx 'dialplan reload'

echo "Verificando peers conectados"
sudo asterisk -rx 'sip show peers'
