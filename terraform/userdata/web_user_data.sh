#cloud-config

package_update: true
package_upgrade: true

packages:
  - git
  - curl

write_files:
  - path: /opt/setup/deploy.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      # Clone the repository containing deployment scripts
      git clone https://github.com/neil1taylor/simple-three-tier-app.git /opt/deployment
      
      # Run the web tier script
      chmod +x /opt/deployment/scripts/web-tier.sh
      /opt/deployment/scripts/web-tier.sh
      
      # Log completion
      echo "$(date): Web tier deployment completed" >> /var/log/deployment.log

runcmd:
  - /opt/setup/deploy.sh