# Kerlink Wirnet Station

This repository contains firmware and tools used to connect Kerlink Wirnet Station gateway to The Things Network Stack for LoRaWAN.

# Provisioning

## Description

The repository contains interactive `provision.sh` script, which can be used to provision a Kerlink Wirnet Station gateway to route traffic to The Things Network Stack for LoRaWAN.

`provision.sh` takes 2 arguments: `GATEWAY-ADDRESS` and `STACK-ADDRESS` and configures the gateway at `GATEWAY-ADDRESS` to use `STACK-ADDRESS`.

In case CPF is not installed on the gateway, the script will attempt to install it using the firmware releases available at this repository. In case gateway version is outdated and, hence, incompatible with CPF, it will attempt to update the gateway firmware first.

The script prompts you before installing firmware and/or rebooting the gateway. This is useful in cases where you might want to customize installation by e.g. modifying the DOTA scripts.

The script is compatible with any Kerlink Wirnet Station gateway running firmare version `3.0` and above.

## Examples

- `./provision.sh '192.168.188.101' 'https://thethings.example.com'`

This would provision gateway at `192.168.188.101` to use `https://thethings.example.com` as Network Server.

In case gateway already had CPF installed, the execution would look like this:

```
./provision.sh '192.168.188.101' 'https://thethings.example.com'
Setting LNS address to https://thethings.example.com...
Setting LNS uplink port to 1700...
Setting LNS downlink port to 1700...
```

In case gateway was running outdated firmware (e.g. `3.5`), the execution would look like this:

```
./provision.sh '192.168.188.101' 'https://thethings.example.com'
CPF is not installed, attempt CPF '1.1.6' installation?[y/n]y
Gateway firmware version is '3.5', which is lower than '3.6' required by CPF, attempt firmware update to '3.6'?[y/n]y
Downloading firmware from 'https://github.com/TheThingsNetwork/kerlink-station-firmware/releases/download/wirnet-3.6/fwupgrade_wirmav2_wirnet_v3.6.tar.gz' to '/run/user/1000/tmp.3sb4TlkWRc/dota.tar.gz' locally...
Pushing '/run/user/1000/tmp.3sb4TlkWRc/dota.tar.gz' to '/mnt/fsuser-1/dota/dota.tar.gz'...
Firmware successfully pushed, reboot gateway to start update?[y/n]y
Waiting for 192.168.188.101 to reboot............[down]......................................
# Host 192.168.188.101 found: line 30
/home/rvolosatovs/.ssh/known_hosts updated.
Original contents retained as /home/rvolosatovs/.ssh/known_hosts.old
Downloading firmware from 'https://github.com/TheThingsNetwork/kerlink-station-firmware/releases/download/wirnet-3.6/custo_knetd-4.12.tar.gz' to '/run/user/1000/tmp.SVnxRHfdfD/dota.tar.gz' locally...
Pushing '/run/user/1000/tmp.SVnxRHfdfD/dota.tar.gz' to '/mnt/fsuser-1/dota/dota.tar.gz'...
Firmware successfully pushed, reboot gateway to start update?[y/n]y
Waiting for 192.168.188.101 to reboot............[down]............
Downloading firmware from 'https://github.com/TheThingsNetwork/kerlink-station-firmware/releases/download/cpf-1.1.6/dota_cpf_1.1.6-1.tar.gz' to '/run/user/1000/tmp.Qr60nW4dWc/dota.tar.gz' locally...
Pushing '/run/user/1000/tmp.Qr60nW4dWc/dota.tar.gz' to '/mnt/fsuser-1/dota/dota.tar.gz'...
Firmware successfully pushed, reboot gateway to start update?[y/n]y
Waiting for 192.168.188.101 to reboot............[down]....................................
Setting LNS address to https://thethings.example.com...
Setting LNS uplink port to 1700...
Setting LNS downlink port to 1700...
```
