# Batch User Management Tools for Linux environments

A lightweight toolkit of Bash scripts to streamline SSH user provisioning, key management, and access validation across your Linux servers.

> A collection of bash scripts for managing SSH users, keys, and access verification in Linux environments.

## 📁 Directory Structure

```
batch_linux_user_insert/
├── ssh_keys/              # SSH public keys directory
├── users.csv              # User configuration
├── usergen.sh             # User generation script
├── verify_keys.sh         # Key verification script
├── cleanup.sh             # User cleanup script
└── logintest.sh           # Login testing script
```

## 📋 Prerequisites

* Linux/Unix environment
* Bash shell 4.0+
* sudo privileges
* OpenSSH server
* `dos2unix` (optional)

## 🔧 Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/LloBi23/batch_linux_user_insert.git
   cd batch_linux_user_insert
   ```

2. Make scripts executable:

   ```bash
   chmod +x *.sh
   ```

3. Verify SSH server:

   ```bash
   sudo systemctl status sshd
   ```

## 📄 Configuration Files

### users.csv

```csv
ssh_filename;username;password
user1.txt;user1;secretpass123
user2_key1.txt;user2;userpass456
user2_key2.txt;user2;userpass456
```

* Semicolon-separated (;)
* Header required
* Multiple keys per user supported

### SSH Key Files (`ssh_keys/*.txt`)

```
ssh-rsa AAAAB3NzaC1yc2EAAA... user@host
```

* Standard SSH public key format
* One key per file
* `.txt` extension required

## 🛠️ Usage

### User Generation

```bash
sudo ./usergen.sh users.csv ssh_keys/
```

Creates users and configures SSH access.

### Key Verification

```bash
sudo ./verify_keys.sh users.csv ssh_keys/
```

Verifies SSH key installations.

### User Cleanup

```bash
sudo ./cleanup.sh users.csv        # Interactive
sudo ./cleanup.sh users.csv -b     # Batch mode (list only)
sudo ./cleanup.sh users.csv -y     # Auto-confirm
```

Removes unwanted user accounts.

### Login Testing

```bash
sudo ./logintest.sh users.csv
```

Tests SSH authentication.

## 📊 Logging

Scripts generate logs in:

* `usergen.log`
* `verify_keys.log`
* `login_tests.log`

## 💾 Backups

`cleanup.sh` creates backups in `backups/`:

* `passwd.YYYYMMDD_HHMMSS`
* `shadow.YYYYMMDD_HHMMSS`

## 🔒 Security

* Minimum 8 character passwords
* SSH directory permissions: 700
* authorized\_keys permissions: 600
* Backup before destructive operations
* Interactive confirmation by default

## ⚠️ Error Handling

All scripts include:

* Input validation
* Error logging
* Status reporting
* Safe defaults
* Timeout protection

## 🔍 Troubleshooting

1. **SSH Connection Failed**

   ```bash
   sudo systemctl restart sshd
   ```

2. **Permission Issues**

   ```bash
   sudo chown -R user:user /home/user/.ssh
   sudo chmod 700 /home/user/.ssh
   sudo chmod 600 /home/user/.ssh/authorized_keys
   ```

3. **Key Verification Failed**

   ```bash
   sudo ./verify_keys.sh users.csv ssh_keys/
   ```

## 👥 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## 📝 License

MIT License

*Built with ❤️ for bash scripts*
