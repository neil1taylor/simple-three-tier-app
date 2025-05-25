# Three Tier Application

This simple three tier application has been designed to deploy an application in IBM Cloud VPC for hands  on lab scenarios. It consists of a set of **cloud-init** files and **script** files. These files collectively create the complete three-tier architecture with:

1. A frontend that users interact with.
2. A backend API that processes requests and communicates with the database.
3. A database that stores persistent data.
4. Configuration tools to connect the tiers together after deployment.

Each tier is designed to be deployed independently and then connected together, making it ideal for demonstrating IBM Cloud VPC infrastructure and networking capabilities.

## Cloud-init files

Cloud-init is a widely used industry-standard method for initializing cloud instances. The cloud-init files for each tier in the application are similar, just changing which script it executes. The key benefits of this approach include the following:

* Centralized Management - All your scripts are stored in a single GitHub repository
* Version Control - Changes to scripts are tracked and can be rolled back if needed
* Simplified Deployment - VSI creation only requires the short cloud-init file, not the entire script

### Understanding the Cloud-Init Files

The basic structure is as follows:

```yaml
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
      # Script content here...

runcmd:
  - /opt/setup/deploy.sh
```

#### Directive Line

```yaml
#cloud-config
```

This is a mandatory first line that tells the system this file is a cloud-init configuration. The system will only process the file if it starts with this exact line.

#### Package Management

```yaml
package_update: true
package_upgrade: true
```

- `package_update: true` - Runs the equivalent of `apt-get update` to update the package lists
- `package_upgrade: true` - Runs the equivalent of `apt-get upgrade` to install the latest versions of all packages

This ensures your system has the latest security patches and software before your application is deployed.

#### Package Installation

```yaml
packages:
  - git
  - curl
```

This section installs the specified packages. In this case:

- `git` - For cloning your GitHub repository
- `curl` - For downloading files or making HTTP requests

#### File Creation

```yaml
write_files:
  - path: /opt/setup/deploy.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      # Script content here...
```

The `write_files` directive creates files on the system with specified content:

- `path` - Where to create the file
- `permissions` - Linux-style octal permissions (here '0755' means read/write/execute for owner, read/execute for group and others)
- `content` - The actual content of the file
    - The pipe symbol `|` allows for multi-line content

In this case, we're creating a deployment script that will:

1. Clone the GitHub repository.
2. Run the appropriate tier initialization script.
3. Log the completion.

#### Command Execution

```yaml
runcmd:
  - /opt/setup/deploy.sh
```

The `runcmd` section runs commands after the system has been initialized. Commands are executed in order and sequentially.

In this example, we're executing the deployment script we created in the previous section. The script will run once the system has booted and all previous cloud-init stages are complete.

#### How It All Works Together

When the VSI boots up:

1. Cloud-init reads the configuration file
2. System packages are updated and upgraded
3. Required packages (git, curl) are installed
4. The deployment script is created
5. The deployment script is executed, which:
   - Clones your GitHub repository
   - Runs the tier-specific initialization script
   - Logs the completion

This entire process happens automatically during instance initialization, with no manual intervention required. The instance will be ready to use as part of your three-tier application once cloud-init completes.

#### Advanced Features Not Shown

Cloud-init has many more capabilities not shown in this example:

- User creation
- SSH key configuration
- Hostname setting
- Network configuration
- Service enablement
- Reboot management
- Inclusion of additional cloud-init modules

These advanced features can be used to further customize your VSI deployment as needed.

## Scripts

There is a script that configures each of the tiers of the application:

* web-tier-init.sh - Configures the web server
* app-tier-init.sh - Configures the app server
* db-tier-init.sh - Configures the database server

### web-tier-init.sh

This script does the following:

1. Updates the OS.
2. Installs Nginx.
3. Creates a file named `/var/www/html/index.html`.
4. Creates a file named `/etc/nginx/sites-available/default`.
5. Applies the Nginx configuration by restarting Nginx.
6. Creates a script named `/usr/local/bin/update-backend-url`. That will be used later to update the backend URL.

#### /var/www/html/index.html

This file:

- Serves as the user interface for the three-tier application
- Provides visual indicators of the status of each tier
- Contains JavaScript to communicate with the backend API
- Includes test buttons to verify the entire stack functionality
- The `APP_TIER_IP` placeholder is replaced by the actual application tier IP address during configuration

#### /etc/nginx/sites-available/default

This is the Nginx server configuration file for the web tier, it:

- Configures Nginx to serve the frontend application
- Sets the document root to `/var/www/html` where our index.html resides
- Listens on port 80 for HTTP requests
- Configures default routing for the web server
- The underscore in `server_name _` means this configuration applies to any hostname

#### /usr/local/bin/update-backend-url

This is a utility script created in the web tier to update the application tier's IP address, it:

- Takes the application tier IP address as an argument
- Uses `sed` to replace the placeholder `APP_TIER_IP` in the index.html file
- Provides feedback confirming the update
- Allows for easy reconfiguration after deployment without editing files manually

### app-tier-init.sh

This script does the following:

1. Updates the OS.
2. Installs nodejs and npm.
3. Create directory for the application `/opt/app`.
4. Creates a file named `package.json` which is is the Node.js package configuration for the application tier.
5. Creates an application server `/opt/app/server.js`.
6. Create a script to update the database URL named `/usr/local/bin/update-db-url`.
7. Install application dependencies.
8. Creates the systemd service for the application.
9. Enables and starts the service.

#### /opt/app/package.json

This is the Node.js package configuration for the application tier, it 

- Defines the application's metadata and dependencies
- Specifies the entry point (`server.js`)
- Lists required npm packages:
    - `express` - Web framework for creating the API
    - `pg` - PostgreSQL client for database connectivity
    - `cors` - Middleware to enable Cross-Origin Resource Sharing, allowing the frontend to communicate with the backend

#### /opt/app/server.js

This is the application configuration file, it:

- Defines the listeniung TCP port: `3000`.
- Creates PostgreSQL connection pool to the database VSI:
    - on port `5432`.
    - to the database named `testdb`.
    - using username `testuser`.
    - and password `testpassword`.

#### /usr/local/bin/update-db-url

This is a utility script created in the application tier to update the database tier's IP address, it:

- Takes the database tier IP address as an argument.
- Uses `sed` to replace the placeholder `DB_TIER_IP` in the server.js file.
- Provides feedback confirming the update.
- Enables easy reconfiguration of the database connection without manual editing.

#### /etc/systemd/system/app-server.service

This is the systemd service file for the application tier, it:

- Creates a systemd service to manage the Node.js application.
- Ensures the application starts automatically when the system boots.
- Configures the working directory and command to start the application.
- Sets up automatic restart if the application fails.
- Makes the application run in the background as a proper service.

### db-tier-init.sh

This script does the following:

* Updates the system and installs PostgreSQL.
* Configures PostgreSQL to listen on all interfaces.
* Allows connections from the application tier.
* Restarts PostgreSQL to apply the changes.
* Creates a test database and user.

#### /etc/postgresql/*/main/pg_hba.conf

This is PostgreSQL's host-based authentication configuration file, it:

- Controls which clients can connect to the PostgreSQL server.
- The added line permits connections from any IP address (`0.0.0.0/0`).
- Requires MD5 password authentication for all connections.
- The wildcard in the path (`/etc/postgresql/*/main/pg_hba.conf`) ensures it works with any PostgreSQL version.
- This is necessary for the application tier to connect to the database tier.

**Security Note:** In a production environment, you would typically restrict this to only allow connections from specific IP addresses (like your application tier's IP) rather than permitting connections from anywhere.

## Terraform Scripts

The terraform scripts provisions all the required resources and provisions the Virtual Server instances with cloud-init userdata scripts that will automatically install and configure the appropriate software for each server type when they're provisioned. The Terraform configuration is in the following files:

1. **main.tf** - Contains all the resource definitions, referencing variables in variables.tf
2. **variables.tf** - Declares all the variables used in the configuration
3. **terraform.tfvars** - Contains all the parameter values for the variables
4. **User Data** - This directory contains the e userdata scripts for the VSIs:
   * web_user_data.yaml: Cloud-init configuration for web tier VSI
   * app_user_data.yaml: Cloud-init configuration for application tier VSI
   * db_user_data.yaml: Cloud-init configuration for database tier VSI
5. **Scripts** - This directory contains the scripts that installs and configures the software in each tier th:
   * web-tier.sh: The main script for setting up the web tier
   * app-tier.sh: The main script for setting up the application tier
   * db-tier.sh: The main script for setting up the database tier

The directory structure is described below:

```
simple-three-tier-app/
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Variable declarations
├── terraform.tfvars        # Variable values
└── userdata/
│   ├── web_user_data.sh    # User data script for web server
│   ├── app_user_data.sh    # User data script for app server
│   └── db_user_data.sh     # User data script for database server
└── scripts/
    ├── web-tier-init.sh    # Configures the web server
    ├── app-tier-init.sh    # Configures the app server
    └── db-tier-init.sh     # Configures the database server
```

The high level instructions are as follows:

   - Step 1: Create a workspace in IBM Schematics
   - Step 2: Configure the variables
   - Step 3: Generate and apply the plan
   - Step 4: Access Your Resources:
      - After deploying all three tiers, you'll need to update the configuration with the correct IP addresses:
         1. SSH into the web tier VSI and run `sudo /opt/deployment/scripts/update-backend-url.sh <app-tier-private-ip>`
         2. SSH into the application tier VSI and run:
               * `sudo /opt/deployment/scripts/update-db-url.sh <db-tier-private-ip>`
               * `sudo systemctl restart app-server`
  
