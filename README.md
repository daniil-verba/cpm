# 🛠️ CPM — CMake Project Manager

A lightweight CLI tool to create, build, and manage CMake projects with zero boilerplate.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Bash](https://img.shields.io/badge/bash-4.0+-green.svg)
![CMake](https://img.shields.io/badge/cmake-3.15+-orange.svg)

## ✨ Features

- 🏗️ Scaffold C++ projects with one command
- 🔨 Build, run, and test without remembering CMake flags
- 📦 Automatic dependency management via FetchContent
- 🧹 Clean build artifacts in one step
- 🎯 Supports Debug / Release / custom presets

## 🚀 Installation

```bash
git clone https://github.com/daniil-verba/cpm.git
cd cpm
chmod +x install.sh
./install.sh
```

Or via curl:

```bash
curl -fsSL https://raw.githubusercontent.com/daniil-verba/cpm/main/install.sh | bash
```

## 📖 Usage

```bash
# Create a new project
cpm new my_app

# Build (defaults to Debug)
cpm build

# Build in Release mode
cpm build --release

# Run the executable
cpm run

# Run tests
cpm test

# Clean build artifacts
cpm clean

# Show project info
cpm info
```

## 📁 Generated Structure

```
my_app/
├── CMakeLists.txt
├── README.md
├── .gitignore
├── src/
│   ├── main.cpp
│   ├── app.cpp
│   └── app.h
├── include/
├── tests/
│   └── test_app.cpp
├── libs/
└── build/
```

## ⚙️ Requirements

- Bash 4.0+
- CMake 3.15+
- A C++ compiler (GCC / Clang / MSVC)

## 🗑️ Uninstall

```bash
cpm uninstall
# or
./install.sh --uninstall
```

## 📄 License

MIT © [Daniil Verba](https://github.com/daniil-verba)

