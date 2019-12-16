choco install openvpn -y
Copy-Item -Path C:\vagrant\ca.crt -Destination C:\Users\vagrant\OpenVPN\config
Copy-Item -Path C:\vagrant\client_dpm.crt -Destination C:\Users\vagrant\OpenVPN\config
Copy-Item -Path C:\vagrant\client_dpm.key -Destination C:\Users\vagrant\OpenVPN\config
Copy-Item -Path C:\vagrant\dpa_net.ovpn -Destination C:\Users\vagrant\OpenVPN\config
