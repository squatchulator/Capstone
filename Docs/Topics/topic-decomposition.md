## Leahy Center Client Infrastructure Topic Decomposition
The mindmap below outlines the initial decomposition for my topic regarding constructing infrastructure for a client of the Leahy Center.
### Mindmap
### Outline
## Leahy Center Client Infrastructure
## Hardware
The client of LC that we are looking to do infrastructure for currently has a working network set up. They have a Unifi Gateway that acts as the gateway and firewall, several switches connected to this firewall to allow connectivity to workstations, and access points connected to the firewall for wireless connectivity. They also have a modem providing gigabit ethernet to connected devices.
New hardware that we would need in order to get a managable AD hierarchy will primarily consist of a domain controller, and other networking equipment such as additional CAT6 cable.
## Software
Not much will need to be done in terms of software. Mainly setting up the Active Directoy hierarchy on the DC, and installing agents on endpoints/the DC. Lots of the software at this client is already managed and configured by the IT team at the Leahy Center.
## Configuration
Once set up, the firewall will need to be configured to allow the traffic we want through. Thankfully the Unifi firewall is very easy to do this on. 
Agents will need to be installed on the DC and endpoints, which will consist of the Ninja agent for remote management and monitoring, the SentinelOne agent for security, and the Elastic agent to collect and forward logs to the Leahy Center's stack. 
Lastly and most importantly, the Domain Controller will need to be configured with Windows and the OU structure will need to be created. Due to high user turnover at this client's establishment, users will likely work on a heavily restricted guest account whereas management will operate with permissions outlined in AD.
## Cabling/Setup
It is likely that the Domain Controller will not fit in the small server 5u server rack this client uses for the firewall and a switch, so it's probable that a new rack will need to be purchased and in this case, the firewall and this switch will need to be recabled. Clean and organized cable management is crucial in order for this infrastructure to be maintained in the future.
## Compliance
To be honest I am not entirely sure what guidelines we will need to follow, as this organization does not deal with much in terms of user information. Health data of the employees will be protected under HIPAA.
## Training
General users will not need to be trained, but will need to be informed somehow of best-practicies and what is off-limits on the client's workstations, as issues have arose before. Management will need to be filled in on what AD is, what it is doing, and what will change when implemented. As for the Leahy Center workforce, documentation on the strucutre of this client will be necessary in order to maintain it in the future.
