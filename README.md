# Kerlink Wirnet Firmware

This repository contains firmware and tools used to connect Kerlink Wirnet gateways to The Things Network Stack for LoRaWAN.

# Provisioning

## Description

The repository contains interactive `provision.sh` script, which can be used to provision Kerlink Wirnet gateways to route traffic to The Things Network Stack for LoRaWAN.

`provision.sh` takes exactly 5 arguments: `GATEWAY-MODEL`, `GATEWAY-ADDRESS`, `STACK-ADDRESS`, `GATEWAY-ID`, `API-KEY`. and configures the gateway at `GATEWAY-ADDRESS` to use configuration for gateway `GATEWAY-ID` acquired from the stack at `STACK-ADDRESS` using API key `API-KEY`. `GATEWAY-MODEL` determines the model of the gateway, possible values are:

- `wirnet-station` - Kerlink Wirnet Station
- `wirnet-istation` - Kerlink Wirnet iStation

In case gateway model is `wirnet-station` and CPF is not installed on the gateway, the script will attempt to install it using the firmware releases available at this repository. In case gateway version is outdated and, hence, incompatible with CPF, it will attempt to update the gateway firmware first.

The script prompts you before installing firmware and/or rebooting the gateway. This is useful in cases where you might want to customize installation by e.g. modifying the DOTA scripts.

The script is compatible with any Kerlink Wirnet iStation gateway or Kerlink Wirnet Station gateway running firmare version `3.0` and above.

## Example

- `./provision.sh 'wirnet-station' '192.168.4.155' 'thethings.example.com' 'example-gtw' 'NNSXS.GTSZYGHE4NBR4XJZHJWEEMLXWYIFHEYZ4WR7UAI.YAT3OFLWLUVGQ45YYXSNS7HTVTFALWYSXK6YLJ6BDUNBPJMRH3UQ'`

This would provision Kerlink Wirnet Station gateway at `192.168.4.155` to use configuration of `example-gtw` provided by stack located at `thethings.example.com`.

In case gateway already had CPF installed, the script would just fetch the Lorad and Lorafwd configurations, activate them and restart CPF.
In case gateway was running outdated firmware (e.g. `3.5`) or CPF was not installed, it would attempt to update the gateway and install CPF before performing the steps above.
