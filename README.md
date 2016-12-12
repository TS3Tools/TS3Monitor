# TS3Monitor

Monitor your TeamSpeak 3 / TSDNS server instances using **TS3Monitor**.

It will check the status of your TeamSpeak 3 / TSDNS server instance and if it has crashed, it will try to restart it.

The **TS3Monitor** provides you also an autostart feature of the configured instances after a reboot or crash of the entire Root server/VPS/virtual machine.

## Table of content
- [Developers](#developers)
- [Main Features](#main-features)
- [Special Features](#special-features)
- [Stay tuned!](#stay-tuned)
- [Requirements](#requirements)
- [Supports](#supports)
- [Installation](#installation)
- [Script licenses](#script-licenses)
	- [Get Professional / Enterprise license](#get-professional-enterprise-license)
- [Donations](#donations)

[Open CHANGELOG](CHANGELOG.md)

[Open GNU GPLv3 license](LICENSE_GNU_GPL.md)

## Developers

 * Sebastian Kraetzig [info@ts3-tools.info]

## Main Features

- TeamSpeak 3 server instance status check
- TSDNS server instance status check

## Special Features

- E-Mail notification
- TeamSpeak 3 / TSDNS server instance restart
- Linux autostarts for TeamSpeak 3 / TSDNS server instance

## Stay tuned!

- [Official Project Homepage](https://www.ts3-tools.info/)
- [facebook Fanpage](https://www.facebook.com/TS3Tools)
- [GitHub](https://github.com/TS3Tools/TS3Monitor/)

## Requirements

- Linux (should work on the most distributations)
- One or more installed TeamSpeak 3 or TSDNS server instances on a Root server/VPS/virtual machine
- Software packages
  - bash (GNU Bourne Again SHell)
  - which
  - grep (GNU grep, egrep and fgrep)
  - any MTA like postfix or exim (for receiving notification mails)
- root user access on your Linux system (below a list of some reasons, why the script needs root permissions)

## Supports

- TeamSpeak 3 server
- TeamSpeak DNS (TSDNS)
- [TS3UpdateScript](https://github.com/TS3Tools/TS3UpdateScript/)

## Installation

Download the latest version of this script to your Linux server:

``wget https://github.com/TS3Tools/TS3Monitor/archive/master.zip``

Unzip it:

``unzip master.zip``

Make the script executable:

``chmod +x TS3Monitor``

Configure it by editing the ``configs/config.all`` file using a text editor of your choice like ``nano`` or ``vim``:

``vim configs/config.all``

Next, add a cronjob using the parameter ``--install-cronjob``:

``./TS3Monitor ts3server --path /home/teamspeak/ --install-cronjob``

``./TS3Monitor tsdnsserver --path /home/teamspeak/tsdns/ --install-cronjob``

You can adjust the cronjob by editing the cron file ``/etc/cron.d/TS3Monitor``:

``*/5 * * * * bash /root/TS3Monitor-master/TS3Monitor ts3server --path /home/teamspeak/``

The above example would install a cronjob, which checks every 5 minutes the status of the ``ts3server`` in ``/home/teamspeak/``.

``*/5 * * * * bash /root/TS3Monitor-master/TS3Monitor tsdns --path /home/teamspeak/tsdns/``

The above example would install a cronjob, which checks every 5 minutes the status of the ``tsdnsserver`` in ``/home/teamspeak/tsdns/``.

The below example would check every single minute (every 60 seconds) the status of the ``ts3server`` in ``/home/teamspeak/``.

``* * * * * bash /root/TS3Monitor-master/TS3Monitor ts3server --path /home/teamspeak/``

## Script licenses

Name | Ideal for | Restrictions | 1-year Support | Costs
:------------- | :------------- | :------------- | :------------- | :-------------
Free | Unlicensed, NPL, AAL | Single Instance, minimum 60 minutes check | No | Free of charge / 'Pay what you want'-Donation
Professional | Unlicensed, NPL, AAL | Single Instance, minimum 30 minutes check | No | 19.99 EUR
Enterprise | ATHP | None | Yes | 49.99 EUR

### Get Professional / Enterprise license

Send me your license information to get a invoice, which you need to pay:

  user@tux:~$ ./TS3Monitor --request-license [Your invoice E-Mail address] [professional | enterprise]

  user@tux:~$ ./TS3Monitor --request-license you@example.com professional

Hint: You should receive a copy of this email within a few minutes. If not, your server is may not able to send emails. Please follow the alternative instructions instead.

Alternative you can send me those details manual via email to [info@ts3-tools.info](info@ts3-tools.info):
- Your (invoice) E-Mail address
- Product name (TS3Monitor)
- Public/WAN IP address, where you want to use the script
- License key of your script (Parameter '--show-license-key')
- Type of license, which you want: Professional or Enterprise

After you've paid the invoice, your script will be licensed within the next 48 hours. Usually, it only takes up to 24 hours.

### Extended support subscription plans

If you only have bought a Professional license or just require more support, you can buy a renewable support subscription plan.

Below are the available subscription plans including their SLA:

Name | Included support | SLA Respond time | Costs
:------------- | :------------- | :------------- | :------------- | :-------------
Basis SLA | 1 year | Within a week | 14.99 EUR
Professional SLA | 1 year | Within 48 hours | 49.99 EUR
Enterprise SLA | 3 year | Within 48 hours | 119.99 EUR

## Donations

**TS3Monitor** is free software and is made available free of charge. Your donation, which is purely optional, supports me at improving the software as well as reducing my costs of this project. If you like the software, please consider a donation. Thank you very much!

[Donate with PayPal](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=7ZRXLSC2UBVWE)
