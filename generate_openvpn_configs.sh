#!/bin/bash

# This script demonstrates the generation of OpenVPN server and client configuration files,
# along with necessary cryptographic assets, simulating the manual setup process.
# It uses openssl for certificate generation, as a standalone alternative to easy-rsa.

# --- Configuration Variables ---
OVPN_DIR="openvpn_configs_demo"
SERVER_IP="YOUR_SERVER_PUBLIC_IP" # Replace with your server's public IP
CLIENT_NAME="myclient"
CA_CN="OpenVPN-CA"
SERVER_CN="OpenVPN-Server"
KEY_BITS=2048

echo "--- OpenVPN Configuration Demonstrator ---"
echo "This script will create a directory '$OVPN_DIR' and generate sample OpenVPN configuration files and keys."
echo "It simulates the steps for setting up a CA, server, and client certificates."
echo "-----------------------------------------"

# Create working directory
mkdir -p "$OVPN_DIR"
cd "$OVPN_DIR" || { echo "Failed to create/enter directory $OVPN_DIR"; exit 1; }

echo ""
echo "[Step 1/7] Generating Certificate Authority (CA) key and certificate..."
# Generate CA private key
openssl genrsa -out ca.key "$KEY_BITS"
# Generate CA certificate
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/CN=$CA_CN/O=OpenVPN Demo/OU=CA"

echo ""
echo "[Step 2/7] Generating Server key, certificate request, and signing with CA..."
# Generate Server private key
openssl genrsa -out server.key "$KEY_BITS"
# Generate Server Certificate Signing Request (CSR)
openssl req -new -key server.key -out server.csr -subj "/CN=$SERVER_CN/O=OpenVPN Demo/OU=Server"
# Sign Server CSR with CA
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 3650 -extfile <(printf "subjectAltName=DNS:$SERVER_CN,IP:$SERVER_IP\nextendedKeyUsage=serverAuth")

echo ""
echo "[Step 3/7] Generating Client key, certificate request, and signing with CA..."
# Generate Client private key
openssl genrsa -out "$CLIENT_NAME".key "$KEY_BITS"
# Generate Client Certificate Signing Request (CSR)
openssl req -new -key "$CLIENT_NAME".key -out "$CLIENT_NAME".csr -subj "/CN=$CLIENT_NAME/O=OpenVPN Demo/OU=Client"
# Sign Client CSR with CA
openssl x509 -req -in "$CLIENT_NAME".csr -CA ca.crt -CAkey ca.key -CAcreateserial -out "$CLIENT_NAME".crt -days 3650 -extfile <(printf "extendedKeyUsage=clientAuth")

echo ""
echo "[Step 4/7] Generating Diffie-Hellman parameters (may take a while)..."
# Generate Diffie-Hellman parameters for key exchange
openssl dhparam -out dh.pem "$KEY_BITS"

echo ""
echo "[Step 5/7] Generating HMAC firewall key (ta.key) for TLS-Auth..."
# Generate a static pre-shared key for TLS-Auth (HMAC firewall)
openvpn --genkey --secret ta.key

echo ""
echo "[Step 6/7] Creating sample OpenVPN server configuration (server.conf)..."
# Create server.conf
cat <<EOF > server.conf
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0 # This is '0' for server
cipher AES-256-CBC
auth SHA256
server 10.8.0.0 255.255.255.0 # VPN subnet
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
comp-lzo # Deprecated, but common in older setups like Debian 8 context
persist-key
persist-tun
status openvpn-status.log
verb 3
explicit-exit-notify 1
EOF
echo "server.conf created."

echo ""
echo "[Step 7/7] Creating sample OpenVPN client configuration ($CLIENT_NAME.ovpn)..."
# Create client.ovpn
cat <<EOF > "$CLIENT_NAME".ovpn
client
dev tun
proto udp
remote $SERVER_IP 1194 # Replace with your server's public IP
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
auth SHA256
key-direction 1 # This is '1' for client
comp-lzo # Deprecated, but common in older setups like Debian 8 context
verb 3

<ca>
$(cat ca.crt)
</ca>
<cert>
$(cat "$CLIENT_NAME".crt)
</cert>
<key>
$(cat "$CLIENT_NAME".key)
</key>
<tls-auth>
$(cat ta.key)
</tls-auth>
EOF
echo "$CLIENT_NAME".ovpn created.

echo ""
echo "--- Important Network Configuration Commands (for your Debian 8 server) ---"
echo "These commands enable IP forwarding and configure basic NAT with iptables."
echo "Remember to replace 'eth0' with your server's actual public-facing network interface."
echo ""
echo "# Enable IP forwarding (add to /etc/sysctl.conf and apply):"
echo "echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf"
echo "sudo sysctl -p"
echo ""
echo "# Basic iptables NAT rules (replace 'eth0' with your public interface):"
echo "sudo iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT"
echo "sudo iptables -A FORWARD -s 10.8.0.0/24 -j ACCEPT"
echo "sudo iptables -A FORWARD -j REJECT --reject-with icmp-host-prohibited"
echo "sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE"
echo ""
echo "# Save iptables rules (on Debian 8, you might use iptables-persistent):"
echo "sudo apt-get install -y iptables-persistent"
echo "sudo netfilter-persistent save"
echo "sudo netfilter-persistent reload"
echo "-------------------------------------------------------------------------"

echo ""
echo "Demonstration complete. Check the '$OVPN_DIR' directory for generated files."
echo "Remember to replace '$SERVER_IP' in the client configuration with your actual server IP."
echo "And 'eth0' in iptables rules with your actual public interface."

# Go back to original directory
cd ..
