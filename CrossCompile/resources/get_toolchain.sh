#/usr/bin/sh

#Get toolchain
wget ftp://{wikiuser}:{wikipasswd}@ftp.kerlinkm2mtechnologies.fr/_kerlink/arm-2011.03-wirma2-r59.tar.xz
mkdir /opt/toolchains
cd /opt/toolchains
tar xJf /arm-2011.03-wirma2-r59.tar.xz
rm /arm-2011.03-wirma2-r59.tar.xz
