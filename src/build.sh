#!/usr/bin/env bash

set -euo pipefail

# Название проекта по умолчанию (переопределяется или читается из CMakeLists)
PROJECT_NAME="cpp_project"
BUILD_ROOT="build"

# Цвета для вывода в терминал
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}-->${NC} $1"; }
log_error() { echo -e "${RED}Error:${NC} $1"; }
log_success() { echo -e "${GREEN}-->${NC} $1"; }

show_help() {
    echo "Usage: cpm [COMMAND] [ARGUMENT]"
    echo ""
    echo "Commands:"
    echo "  build [type]    Build the project (type: debug/release, default: debug)"
    echo "  clean           Remove the build directory"
    echo "  rebuild [type]  Clean and build the project from scratch"
    echo "  run [type]      Build the project (if needed) and run it"
    echo "  test            Run project tests using CTest"
    echo "  add <repo>      Add a GitHub library dependency (e.g., nlohmann/json)"
    echo "  remove <name>   Remove a library dependency from the project"
    echo "  new <name>      Create a new project directory with Git initialized"
    echo "  init            Initialize a project in the current directory with Git"
    echo "  help, -h        Show this help message"
}

check_dependencies() {
    for cmd in cmake make git; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "'$cmd' is not installed. Please install it to proceed."
            exit 1
        fi
    done
}

get_build_dir() {
    local type="${1:-debug}"
    type=$(echo "$type" | tr '[:upper:]' '[:lower:]')
    
    if [ "$type" = "release" ]; then
        echo "$BUILD_ROOT/release:Release"
    else
        echo "$BUILD_ROOT/debug:Debug"
    fi
}

# Автоматическое чтение имени проекта из CMakeLists.txt
if [ -f "CMakeLists.txt" ]; then
    PROJECT_NAME=$(grep -i "project(" CMakeLists.txt | sed -E 's/project\s*\(\s*([^ )]+).*/\1/I' || echo "$PROJECT_NAME")
fi

# Вспомогательная функция для генерации структуры файлов и настройки Git
create_project_files() {
    local p_name="$1"
    
    # Инициализация Git, если репозитория еще нет
    if [ ! -d ".git" ]; then
        log_info "Initializing Git repository..."
        git init
        git branch -m main
    fi

    # Создание .gitignore
    if [ ! -f ".gitignore" ]; then
        cat << EOF > .gitignore
# CMake build directories
/${BUILD_ROOT}/
/CMakeSettings.json
/CMakeUserPresets.json

# IDEs and editors
/.vscode/
/.idea/
*.swp
*.swo

# OS generated files
.DS_Store
Thumbs.db
EOF
        log_success "Created .gitignore"
    fi

    # Создание структуры исходников
    mkdir -p src include
    
    if [ ! -f "src/main.cpp" ]; then
        cat << EOF > src/main.cpp
#include <iostream>

int main() {
    std::cout << "Hello from ${p_name}!" << std::endl;
    return 0;
}
EOF
        log_success "Created src/main.cpp"
    fi

    if [ ! -f "CMakeLists.txt" ]; then
        cat << EOF > CMakeLists.txt
cmake_minimum_required(VERSION 3.14) # Рекомендуется 3.14+ для FetchContent
project(${p_name} VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)

# <CPM_DEPENDENCIES_START>
# </CPM_DEPENDENCIES_END>

include_directories(include)

file(GLOB_RECURSE SOURCES "src/*.cpp")
add_executable(\${PROJECT_NAME} \${SOURCES})

# <CPM_LINK_START>
# </CPM_LINK_START>
EOF
        log_success "Created CMakeLists.txt"
    fi
}

cmd_clean() {
    if [ -d "$BUILD_ROOT" ]; then
        log_info "Removing '$BUILD_ROOT' directory..."
        rm -rf "$BUILD_ROOT"
        log_success "Cleaned!"
    else
        log_info "Directory '$BUILD_ROOT' does not exist. Nothing to clean."
    fi
}

cmd_build() {
    check_dependencies
    local build_info
    build_info=$(get_build_dir "${1:-debug}")
    local b_dir="${build_info%%:*}"
    local b_type="${build_info#*:}"

    log_info "Configuring CMake in [${b_type}] mode for project '$PROJECT_NAME'..."
    cmake -B "$b_dir" -S . -DCMAKE_BUILD_TYPE="$b_type"
    
    log_info "Building project..."
    cmake --build "$b_dir" --parallel "$(nproc 2>/dev/null || echo 2)"
    log_success "Build finished successfully!"
}

cmd_run() {
    local type="${1:-debug}"
    cmd_build "$type"
    
    local build_info
    build_info=$(get_build_dir "$type")
    local b_dir="${build_info%%:*}"
    
    local target_path="./$b_dir/$PROJECT_NAME"
    if [ -f "$target_path" ]; then
        log_success "Running $PROJECT_NAME..."
        echo "========================================="
        "$target_path"
    else
        log_error "Executable '$target_path' not found. Check CMakeLists.txt target name."
        exit 1
    fi
}

cmd_new() {
    local p_name="${1:-}"
    if [ -z "$p_name" ]; then
        log_error "The project name is required for 'new' command."
        echo "Usage: $0 new <project_name>"
        exit 1
    fi

    local target_dir="./$p_name"
    if [ -d "$target_dir" ]; then
        log_error "Directory '$p_name' already exists."
        exit 1
    fi

    log_info "Creating new project directory: $target_dir"
    mkdir -p "$target_dir"
    cd "$target_dir"

    create_project_files "$p_name"
    log_success "Project '$p_name' successfully created!"
    log_info "Run 'cd $p_name' to enter your project."
}

cmd_init() {
    if [ "$PWD" = "$HOME" ]; then
        log_error "Cannot initialize project directly in the HOME directory ($HOME)."
        log_error "Please use '$0 new <name>' to create a dedicated project directory."
        exit 1
    fi

    local p_name
    p_name=$(basename "$PWD")

    log_info "Initializing project '$p_name' in the current directory..."
    create_project_files "$p_name"
    log_success "Project '$p_name' successfully initialized!"
}

cmd_test() {
    cmd_build "debug"
    log_info "Running tests via CTest..."
    cd "$BUILD_ROOT/debug" && ctest --output-on-failure
}

cmd_add() {
    local repo="${1:-}"
    if [ -z "$repo" ]; then
        log_error "Please specify a GitHub repository. Example: cpm add nlohmann/json"
        exit 1
    fi

    if [ ! -f "CMakeLists.txt" ]; then
        log_error "CMakeLists.txt not found! Are you in the project root directory?"
        exit 1
    fi

    local lib_name="${repo#*/}"
    lib_name=$(echo "$lib_name" | tr '[:upper:]' '[:lower:]' | tr '-' '_')

    if grep -q "FetchContent_Declare(${lib_name}" CMakeLists.txt; then
        log_info "Library '$lib_name' is already added to the project."
        exit 0
    fi

    log_info "Adding dependency '$repo' as '$lib_name'..."

    local fetch_block="FetchContent_Declare(\\n    ${lib_name}\\n    GIT_REPOSITORY https://github.com{repo}.git\\n    GIT_TAG main\\n)\\nFetchContent_MakeAvailable(${lib_name})\\n# <CPM_DEPENDENCIES_START>"
    local link_block="target_link_libraries(\\\${PROJECT_NAME} PRIVATE ${lib_name})\\n# <CPM_LINK_START>"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/# <CPM_DEPENDENCIES_START>/$fetch_block/g" CMakeLists.txt
        sed -i '' "s/# <CPM_LINK_START>/$link_block/g" CMakeLists.txt
    else
        sed -i "s/# <CPM_DEPENDENCIES_START>/$fetch_block/g" CMakeLists.txt
        sed -i "s/# <CPM_LINK_START>/$link_block/g" CMakeLists.txt
    fi

    log_success "Successfully added '$repo' to CMakeLists.txt!"
    log_info "Run 'cpm build' to download and compile the library."
}

cmd_remove() {
    local repo="${1:-}"
    if [ -z "$repo" ]; then
        log_error "Please specify the library to remove. Example: cpm remove json"
        exit 1
    fi

    local lib_name="${repo#*/}"
    lib_name=$(echo "$lib_name" | tr '[:upper:]' '[:lower:]' | tr '-' '_')

    if [ ! -f "CMakeLists.txt" ]; then
        log_error "CMakeLists.txt not found!"
        exit 1
    fi

    log_info "Removing dependency '$lib_name'..."

    # Чистим упоминания библиотеки из CMakeLists.txt
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "/${lib_name}/d" CMakeLists.txt
    else
        sed -i "/${lib_name}/d" CMakeLists.txt
    fi

    log_success "Removed reference to '$lib_name' from CMakeLists.txt."
}

# ==========================================

COMMAND="${1:-help}" # По умолчанию теперь help, чтобы не триггерить билд
SECOND_ARG="${2:-}"

case "$COMMAND" in
    clean)
        cmd_clean
        ;;
    build)
        cmd_build "${SECOND_ARG:-debug}"
        ;;
    rebuild)
        cmd_clean
        cmd_build "${SECOND_ARG:-debug}"
        ;;
    run)
        cmd_run "${SECOND_ARG:-debug}"
        ;;
    test)
        cmd_test
        ;;
    add)
        cmd_add "$SECOND_ARG"
        ;;
    remove)
        cmd_remove "$SECOND_ARG"
        ;;
    new)
        cmd_new "$SECOND_ARG"
        ;;
    init)
        cmd_init
        ;;
    help|-h|--help)
        show_help
        exit 0
        ;;
    *)
        log_error "Unknown command '$COMMAND'"
        show_help
        exit 1
        ;;
esac

