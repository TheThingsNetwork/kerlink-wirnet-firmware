#

mkdir /root/buildroot
mkdir /root/buildroot/bin
mkdir /root/buildroot/bin/lora_gateway
mkdir /root/buildroot/bin/packet_forwarder

cd /root/buildroot
git clone https://github.com/TheThingsNetwork/lora_gateway.git
git clone https://github.com/TheThingsNetwork/packet_forwarder.git

cd /root/buildroot/lora_gateway
make
cp util_pkt_logger/util_pkt_logger /root/buildroot/bin/lora_gateway/util_pkt_logger
cp util_spi_stress/util_spi_stress /root/buildroot/bin/lora_gateway/util_spi_stress
cp util_tx_test/util_tx_test /root/buildroot/bin/lora_gateway/util_tx_test
cp util_tx_continuous/util_tx_continuous /root/buildroot/bin/lora_gateway/util_tx_continuous

cd /root/buildroot/packet_forwarder
make
cp basic_pkt_fwd/basic_pkt_fwd /root/buildroot/bin/packet_forwarder/basic_pkt_fwd
cp gps_pkt_fwd/gps_pkt_fwd /root/buildroot/bin/packet_forwarder/gps_pkt_fwd
cp beacon_pkt_fwd/beacon_pkt_fwd /root/buildroot/bin/packet_forwarder/beacon_pkt_fwd
cp poly_pkt_fwd/poly_pkt_fwd /root/buildroot/bin/packet_forwarder/poly_pkt_fwd
cp util_ack/util_ack /root/buildroot/bin/packet_forwarder/util_ack
cp util_sink/util_sink /root/buildroot/bin/packet_forwarder/util_sink
cp util_tx_test/util_tx_test /root/buildroot/bin/packet_forwarder/util_tx_test

# cd /root/buildroot/
# tar -cvzf bin.tar.gz ./bin





echo "\n \n All Done! \n \n"
