## README: DevOps Zsh Environment Setup

This project provides an automated bash script to configure a productive Zsh environment tailored for DevOps workflows. It streamlines the installation of Zsh, Oh My Zsh, essential plugins, and the Powerlevel10k theme across multiple operating systems.

---

### Features

- **Automatic Package Management**: Detects and uses `brew`, `apt`, `pacman`, `dnf`, or `yum` to install dependencies.
- **Oh My Zsh Integration**: Automates the installation of the Oh My Zsh framework.
- **Essential Plugins**: Installs `zsh-autosuggestions` and `zsh-syntax-highlighting` automatically.
- **Theming**: Clones the Powerlevel10k theme for a highly informative terminal prompt.
- **Configuration Sync**: Downloads verified `.zshrc` and `.zsh_snippets_history` files from a remote repository if local versions are not found.
- **Safe Backups**: Automatically backs up existing `.zshrc` files to `.zshrc.bak` before making changes.

---

### Prerequisites

The script targets the following operating systems:

- Ubuntu / Debian
- Arch Linux
- Fedora / RHEL / CentOS
- macOS

---

### Installation

1.  **Clone the repository or download the script**:

    ```bash
    git clone https://github.com/tree-1917/devman.git
    cd devops
    ```

2.  **Make the script executable**:

    ```bash
    chmod +x setup.sh
    ```

3.  **Run the script**:
    ```bash
    ./setup.sh
    ```

---

### Post-Installation

After the script completes successfully, perform the following steps to finalize the environment:

1.  **Switch to Zsh**:
    If your shell did not change automatically, run:

    ```bash
    exec zsh
    ```

2.  **Configure the Theme**:
    The Powerlevel10k configuration wizard should start automatically. If it does not, run:
    ```bash
    p10k configure
    ```

---

### File Structure

- `setup.sh`: The main installation script.
- `.zshrc`: The shell configuration file (Remote fallback available).
- `.zsh_snippets_history`: A custom snippets file for command shortcuts (Remote fallback available).
