# 🏁 Contributing to Ferrari OS

Thank you for your interest in contributing to **Ferrari OS**, the high-performance, Arch-based Linux distro inspired by Ferrari's speed, design, and culture. This project thrives on community effort, and we're thrilled to have you join the pit crew.

---

## 🧰 How to Get Started

1. **Fork the Repo**
   - Click “Fork” on the top right of [this repository](https://github.com/Openverse/Ferrari-OS).
   - Clone your fork locally:
     ```bash
     git clone https://github.com/yourusername/ferrari-os.git
     cd ferrari-os
     ```

2. **Set Up Your Environment**
   - Install required tools:
     ```bash
     sudo pacman -S archiso git base-devel
     ```
   - Run initial ISO build:
     ```bash
     ./scripts/build_iso.sh
     ```

3. **Pick an Issue**
   - Check our [GitHub Issues](https://github.com/Openverse/Ferrari-OS/issues).
   - Comment on the issue to get assigned.
   - Or open a new issue before submitting major features or changes.

---

## 🛠️ Areas to Contribute

- **UI/UX**: Themes, Plymouth, icons, wallpapers.
- **ISO Core**: Pacman config, packages list, systemd tweaks.
- **Custom Tools**: Shell scripts, the Garage toolkit, welcome wizards.
- **Installer**: Post-install configuration, custom walkthroughs.
- **Testing**: QEMU, live USB, bug reports.
- **Docs**: Installation, customization, architecture explanations.

---

## 🚗 Branching Strategy

- `main`: Stable builds only.
- `dev`: Ongoing work, always based off latest.
- `feature/<name>`: Feature-specific contributions.
  ```bash
  git checkout -b feature/your-feature dev
  ```

---

## 🔁 Pull Request Guidelines

- PRs must be from `feature/*` to `dev`.
- Use clear titles and detailed descriptions.
- Test your code before submitting.
- Link to the relevant issue using `Fixes #<issue-number>`.

---

## 💡 Coding Style

- Scripts: Bash (`.sh`) must be POSIX-compliant.
- YAML/JSON: Use 2 spaces indentation.
- Markdown: Keep headings semantic and organized.
- Follow the [ArchWiki standards](https://wiki.archlinux.org/) for clarity.

---

## 🔐 Commit Message Format

Follow conventional commits:
```
feat: add new hyprland theme
fix: correct pacman.conf typo
docs: add installation instructions
refactor: update build script logic
```

---

## 📞 Communication

Join the [Ferrari OS Discord](https://discord.gg/JhQpdUYzbM) or Matrix room to collaborate with other contributors and coordinate tasks.

---

## 🏎️ We Run Fast

This is a high-speed project. Updates, ISO builds, and decisions move quickly. Stay in sync, ask questions, and help us build the fastest OS on the track.
