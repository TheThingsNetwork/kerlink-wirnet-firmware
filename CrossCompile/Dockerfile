#	Setting up VM	##

	#Using latest lts Ubuntu
	FROM ubuntu:12.04

	#Update PackageManager, Update System
	RUN apt-get -y update ; apt-get -y upgrade

#	Some things to make it work! Make sure we got ia32-libs onboard, Install dependencies.

	RUN apt-get -y install wget apt-utils make ia32-libs u-boot-tools lzma zlib1g-dev bison flex yodl

	#We want to use git > install
	#Use --fix-missing!
	RUN apt-get -y install git --fix-missing

	ADD resources/get_toolchain.sh /
	RUN sh /get_toolchain.sh
	ENV PATH=$PATH:/opt/toolchains/arm-2011.03-wirma2/bin
	ENV CROSS_COMPILE=arm-none-linux-gnueabi-

#	Fetch, build and push
	ADD resources/build.sh /
