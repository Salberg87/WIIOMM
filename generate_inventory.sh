#!/bin/bash

# ========== Config ==========
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVENTORY_DIR="$SCRIPT_DIR/inventory"
OLD_INVENTORY_DIR="$HOME/WIIOMM"
mkdir -p "$INVENTORY_DIR"
OUTPUT="$INVENTORY_DIR/inventory_$TIMESTAMP.md"
LATEST_LINK="$INVENTORY_DIR/latest.md"
DIFF_OUTPUT="$INVENTORY_DIR/diff_$TIMESTAMP.md"

# ========== Colors ==========
GREEN='\033[0;92m'
BLUE='\033[0;94m'
BOLD='\033[1m'
RESET='\033[0m'
CYAN='\033[0;96m'
YELLOW='\033[0;93m'

# ========== Cleanup Old Files ==========
if [ -d "$OLD_INVENTORY_DIR" ]; then
    echo -e "\n${BOLD}${CYAN}🧹 Cleaning up old inventory files...${RESET}"
    if [ -d "$OLD_INVENTORY_DIR" ]; then
        echo "Found old inventory directory at: $OLD_INVENTORY_DIR"
        read -p "Would you like to move these files to the new location? (y/n): " MOVE_FILES
        
        if [ "$MOVE_FILES" = "y" ] || [ "$MOVE_FILES" = "Y" ]; then
            # Move files to new location
            mv "$OLD_INVENTORY_DIR"/* "$INVENTORY_DIR/" 2>/dev/null
            echo -e "${GREEN}✅ Files moved successfully${RESET}"
            
            # Remove old directory
            rm -rf "$OLD_INVENTORY_DIR"
            echo -e "${GREEN}✅ Old directory removed${RESET}"
        else
            echo -e "${YELLOW}⚠️ Skipping file migration${RESET}"
        fi
    fi
fi

# ========== Banner ==========
echo -e "${CYAN}"
cat << "EOF"

__        ___ _                          ___ 
\ \      / (_|_) ___  _ __ ___  _ __ ___|__ \
 \ \ /\ / /| | |/ _ \| '_ ` _ \| '_ ` _ \ / /
  \ V  V / | | | (_) | | | | | | | | | | |_| 
   \_/\_/  |_|_|\___/|_| |_| |_|_| |_| |_(_) 
    WIIOMM? → What Is Installed On My Mac?


EOF
echo -e "${RESET}${YELLOW}>> Saving inventory to: $OUTPUT${RESET}"

# ========== Helpers ==========
section() {
    echo -e "\n${BLUE}==> $1${RESET}"
    echo "## $1" >> "$OUTPUT"
}

command_section() {
    section "$1"
    echo -e "${GREEN}$2${RESET}"
    echo "\`\`\`" >> "$OUTPUT"
    eval "$2" >> "$OUTPUT" 2>/dev/null
    echo "\`\`\`" >> "$OUTPUT"
}

# ========== Known Issues & Outdated Packages ==========
check_known_issues() {
  echo -e "\n## 🚨 Known Issues & Outdated Packages" >> "$OUTPUT"

  echo -e "\n### Outdated Homebrew Packages:" >> "$OUTPUT"
  brew outdated >> "$OUTPUT" 2>/dev/null || echo "(brew not found)" >> "$OUTPUT"

  echo -e "\n### Outdated Python Packages:" >> "$OUTPUT"
  pip3 list --outdated >> "$OUTPUT" 2>/dev/null || echo "(pip3 not found)" >> "$OUTPUT"

  echo -e "\n### Outdated Global npm Packages:" >> "$OUTPUT"
  if command -v npm >/dev/null; then
    npm outdated -g --depth=0 >> "$OUTPUT" 2>/dev/null || echo "(npm outdated failed)" >> "$OUTPUT"
  else
    echo "(npm not found)" >> "$OUTPUT"
  fi

  echo -e "\n### Homebrew Known Issues (Caveats):" >> "$OUTPUT"
  for pkg in $(brew list --formula 2>/dev/null); do
    caveats=$(brew info "$pkg" 2>/dev/null | awk '/^==> Caveats/,/^$/' | sed '/^==> Caveats/d')
    if [ -n "$caveats" ]; then
      echo -e "\n#### $pkg" >> "$OUTPUT"
      echo "$caveats" >> "$OUTPUT"
    fi
  done

  echo -e "\n### User-Maintained Known Issues:" >> "$OUTPUT"
  if [ -f "$SCRIPT_DIR/known_issues.txt" ]; then
    while IFS= read -r line; do
      pkg=$(echo "$line" | cut -d: -f1)
      if grep -q "$pkg" "$OUTPUT"; then
        echo "$line" >> "$OUTPUT"
      fi
    done < "$SCRIPT_DIR/known_issues.txt"
  else
    echo "(No known_issues.txt found)" >> "$OUTPUT"
  fi

  echo -e "\n### npm Audit Vulnerabilities:" >> "$OUTPUT"
  if command -v npm >/dev/null; then
    npm_audit_json=$(npm audit --json 2>/dev/null)
    if echo "$npm_audit_json" | jq -e '.advisories != null and (.advisories | length > 0)' >/dev/null 2>&1; then
      echo "$npm_audit_json" | jq -r '.advisories[] | "- [npm] " + .module_name + ": " + .title + " (" + .severity + ")\n  More info: " + .url' >> "$OUTPUT"
    else
      echo "No npm vulnerabilities found." >> "$OUTPUT"
    fi
  else
    echo "(npm not found)" >> "$OUTPUT"
  fi

  echo -e "\n### pip Audit Vulnerabilities:" >> "$OUTPUT"
  if command -v pip-audit >/dev/null; then
    pip_audit_json=$(pip-audit -f json 2>/dev/null)
    if echo "$pip_audit_json" | jq -e '.[0].vulns != null and (.[0].vulns | length > 0)' >/dev/null 2>&1; then
      echo "$pip_audit_json" | jq -r '.[] | select(.vulns != null and (.vulns | length > 0)) | "- [pip] " + .name + ": " + .vulns[0].id + " - " + .vulns[0].description' >> "$OUTPUT"
    else
      echo "No pip vulnerabilities found." >> "$OUTPUT"
    fi
  else
    echo "(pip-audit not found)" >> "$OUTPUT"
  fi

  echo -e "\n### Advisory Links:" >> "$OUTPUT"
  # Homebrew
  for pkg in $(brew list --formula 2>/dev/null); do
    echo "- [Homebrew] $pkg: https://github.com/Homebrew/homebrew-core/issues?q=$pkg" >> "$OUTPUT"
    echo "  GitHub Advisories: https://github.com/advisories?query=$pkg" >> "$OUTPUT"
  done
  # npm
  if command -v npm >/dev/null; then
    for pkg in $(npm list -g --depth=0 --parseable 2>/dev/null | awk -F/ '{print $NF}' | grep -v node_modules); do
      echo "- [npm] $pkg: https://www.npmjs.com/advisories?search=$pkg" >> "$OUTPUT"
      echo "  GitHub Advisories: https://github.com/advisories?query=$pkg" >> "$OUTPUT"
    done
  fi
  # Python
  if command -v pip3 >/dev/null; then
    for pkg in $(pip3 list --format=freeze | cut -d= -f1); do
      echo "- [pip] $pkg: https://pypi.org/project/$pkg/#history" >> "$OUTPUT"
      echo "  GitHub Advisories: https://github.com/advisories?query=$pkg" >> "$OUTPUT"
    done
  fi
}

# ========== Start Writing Inventory ==========
echo "# macOS Environment Inventory - $TIMESTAMP" > "$OUTPUT"
echo "" >> "$OUTPUT"

# Redaction option
REDACT=false
for arg in "$@"; do
  if [ "$arg" = "--redact" ]; then
    REDACT=true
  fi
done

section "System Info"
if $REDACT; then
  # Redact sensitive fields from system_profiler output
  system_profiler SPSoftwareDataType SPHardwareDataType 2>/dev/null | \
    sed -E \
      -e 's/(Computer Name: ).*/\1[REDACTED]/' \
      -e 's/(User Name: ).*/\1[REDACTED]/' \
      -e 's/(Serial Number \(system\): ).*/\1[REDACTED]/' \
      -e 's/(Hardware UUID: ).*/\1[REDACTED]/' \
      -e 's/(Provisioning UDID: ).*/\1[REDACTED]/' \
      -e 's/(Model Number: ).*/\1[REDACTED]/' \
      -e 's/(Activation Lock Status: ).*/\1[REDACTED]/' \
      >> "$OUTPUT"
else
  system_profiler SPSoftwareDataType SPHardwareDataType >> "$OUTPUT" 2>/dev/null
fi

command_section "Homebrew Packages" "brew list --versions"
command_section "Homebrew Casks" "brew list --cask"
command_section "Python Version" "python3 --version"
command_section "pip Packages" "pip3 list"
command_section "Node.js Version" "node -v"
command_section "Global npm Packages" "npm list -g --depth=0"

section "VS Code Extensions"
if command -v code >/dev/null; then
    echo "\`\`\`" >> "$OUTPUT"
    code --list-extensions >> "$OUTPUT"
    echo "\`\`\`" >> "$OUTPUT"
else
    echo "VS Code CLI not found" >> "$OUTPUT"
fi

section "Shell Aliases"
if [ -f ~/.zshrc ]; then
    grep "^alias " ~/.zshrc >> "$OUTPUT"
elif [ -f ~/.bashrc ]; then
    grep "^alias " ~/.bashrc >> "$OUTPUT"
fi

command_section "Xcode CLI Tools" "xcode-select -p"
command_section "User LaunchAgents" "ls ~/Library/LaunchAgents"
command_section "System LaunchAgents & Daemons" "ls /Library/LaunchAgents /Library/LaunchDaemons"

# ========== Compare to Last Run ==========
if [ -f "$LATEST_LINK" ]; then
    echo -e "\n${BOLD}${CYAN}🔍 Comparing to last run...${RESET}"
    if command -v diff >/dev/null; then
        diff --unified "$LATEST_LINK" "$OUTPUT" > "$DIFF_OUTPUT" || true
        ADDED=$(grep -c '^+' "$DIFF_OUTPUT" 2>/dev/null || echo 0)
        REMOVED=$(grep -c '^-' "$DIFF_OUTPUT" 2>/dev/null || echo 0)
        echo -e "${YELLOW}📄 Diff saved to: $DIFF_OUTPUT (${ADDED} additions, ${REMOVED} removals)${RESET}"
    else
        echo -e "${YELLOW}Diff tool not found. No diff generated.${RESET}"
    fi
else
    echo -e "${YELLOW}⚠️ No previous inventory to compare with.${RESET}"
fi

# ========== Update Latest ==========
ln -sf "$(basename "$OUTPUT")" "$LATEST_LINK"

# ========== Git Operations ==========
if [ -d "$SCRIPT_DIR/.git" ]; then
    echo -e "\n${BOLD}${CYAN}📤 Committing to GitHub...${RESET}"
    cd "$SCRIPT_DIR" || exit 1
    
    # Generate detailed commit message
    COMMIT_MSG="📊 Inventory Update: $TIMESTAMP\n\n"
    
    if [ -f "$DIFF_OUTPUT" ]; then
        CHANGES=$(grep -E '^(\+|\-)' "$DIFF_OUTPUT" | grep -v '^---' | grep -v '^+++' | head -n 5)
        if [ -n "$CHANGES" ]; then
            COMMIT_MSG+="Key Changes:\n$CHANGES\n\n"
        fi
    fi
    
    COMMIT_MSG+="Files:\n"
    COMMIT_MSG+="- inventory_$TIMESTAMP.md\n"
    COMMIT_MSG+="- diff_$TIMESTAMP.md\n"
    COMMIT_MSG+="- latest.md (symlink)\n"
    
    # Add the new files
    git add "$OUTPUT" "$DIFF_OUTPUT" "$LATEST_LINK" > /dev/null 2>&1
    
    # Commit with detailed message
    echo -e "$COMMIT_MSG" | git commit -F - > /dev/null 2>&1
    
    # Push to GitHub
    if git push origin main > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Successfully pushed to GitHub${RESET}"
    else
        echo -e "${YELLOW}⚠️ Failed to push to GitHub${RESET}"
    fi
fi

# ========== Done ==========
check_known_issues
echo -e "\n${BOLD}${GREEN}✅ Inventory complete.${RESET}"
echo -e "${YELLOW}See: $OUTPUT${RESET}"