# NetSweep
a lightweight, Bash-based network alerting tool designed for internal network monitoring. It scans your local subnet for unknown devices, compares them against a trusted devices list, and takes one of two actions:

- **Interactive Mode:** When run manually, it displays the unknown devices and prompts you to add them to the trusted list.
- **Automatic Mode:** When run in a non-interactive environment (such as via systemd), it sends email alerts for any new, untrusted devices and logs detailed scan information.

## Features

-  Uses arp-scan to detect devices on the local subnet.
- Compares discovered devices (by IP and MAC address) with a pre-defined trusted devices list.
- Runs an Nmap scan on any unknown device to determine OS and service versions.
- Dual Operation Modes:
  - Interactive Mode: Prompts for manual approval to add devices to the trusted list.
  - Automatic Mode: Sends email alerts using msmtp when rogue devices are detected.
- Logging: Records scan details and Nmap output in a log file.
- Systemd Integration: Designed to be scheduled automatically with a systemd timer for regular scanning.

## Requirements

- Operating System: Linux
- Dependencies:
  - nmap
  - msmtp (with proper configuration in ~/.msmtprc)
- Privileges: Some commands (e.g., arp-scan, nmap) require root privileges. The script automatically escalates when needed.

## Issues

- msmtp automatically reads your SMTP configuration from your ~/.msmtprc file. However, it does not inherit the full user environment by default causing the HOME environment variable to not be set. 

- This can result in errors such as:
    /home/yourusername/.msmtprc: line 11: user: command not found

- To ensure that msmtp finds your ~/.msmtprc configuration file when running under systemd, you need to explicitly set the HOME environment variable in your service file. For example, in your netsweep.service file, add the following line in the [Service] section:

    Environment=HOME=/home/yourusername

## Installation

1. Clone the Repository:

   ```bash
   git clone https://github.com/yourusername/netsweep.git
   cd netsweep
