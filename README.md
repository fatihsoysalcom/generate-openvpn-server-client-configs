# Generate OpenVPN Server Client Configs

This example Bash script demonstrates the core steps involved in setting up an OpenVPN server configuration. It generates self-signed CA, server, and client certificates/keys using `openssl`, creates sample `server.conf` and `client.ovpn` files, and outlines essential network forwarding and firewall commands. The script simulates the manual configuration process described in the article.

## Language

`bash`

## How to Run

1. Save the script as `generate_openvpn_configs.sh`.
2. Make it executable: `chmod +x generate_openvpn_configs.sh`.
3. Run it: `./generate_openvpn_configs.sh`.
4. The script will create a `openvpn_configs_demo` directory with generated files and print network commands.

## Original Article

This example accompanies the Turkish article: [Debian 8 (Jessie) Üzerinde OpenVPN Sunucusu Nasıl Kurulur?](https://fatihsoysal.com/blog/?p=43061).

## License

MIT — see [LICENSE](LICENSE).
