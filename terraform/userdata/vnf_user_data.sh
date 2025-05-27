#cloud-config

hostname: ibm-vnf-node
manage_etc_hosts: true

package_update: true
package_upgrade: false
packages:
  - iproute2
  - iptables
  - net-tools
  - curl
  - tcpdump

write_files:
  - path: /etc/sysctl.d/99-ip-forward.conf
    content: |
      net.ipv4.ip_forward = 1
      net.ipv6.conf.all.forwarding = 1

runcmd:
  # Reload sysctl to apply forwarding
  - sysctl --system

  # Enable forwarding at runtime
  - sysctl -w net.ipv4.ip_forward=1
  - sysctl -w net.ipv6.conf.all.forwarding=1

  # Optional: Enable NAT on primary interface
  - iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE

  # Persist iptables rules (install iptables-persistent if needed)
  - mkdir -p /etc/iptables
  - iptables-save > /etc/iptables/rules.v4

final_message: "IBM VPC VNF setup complete. IP forwarding enabled."
