#!/bin/bash

echo "=== WIIOMM Setup ==="
echo "This script will set up the WIIOMM system for your machine."

# Function to check if repository exists
check_repo_exists() {
    local username=$1
    local repo=$2
    local auth_method=$3
    local token=$4

    if [ "$auth_method" = "1" ]; then
        # SSH check
        if git ls-remote "git@github.com:$username/$repo.git" &>/dev/null; then
            return 0
        fi
    else
        # HTTPS check
        if curl -s -f "https://api.github.com/repos/$username/$repo" > /dev/null; then
            return 0
        fi
    fi
    return 1
}

# Function to create repository
create_repo() {
    local username=$1
    local repo=$2
    local token=$3
    local is_private=$4

    echo "Creating new repository '$repo' on GitHub..."
    if curl -s -X POST -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        -d "{\"name\":\"$repo\",\"private\":$is_private}" \
        "https://api.github.com/user/repos" > /dev/null; then
        return 0
    fi
    return 1
}

# Function to get repository URL
get_repo_url() {
    local username=$1
    local repo=$2
    local auth_method=$3
    
    if [ "$auth_method" = "1" ]; then
        echo "git@github.com:$username/$repo.git"
    else
        echo "https://github.com/$username/$repo"
    fi
}

# Get GitHub repository information
read -p "Enter your GitHub username: " GITHUB_USERNAME
read -p "Enter your repository name (default: wiiomm): " GITHUB_REPO
GITHUB_REPO=${GITHUB_REPO:-wiiomm}

# Get git user information
read -p "Enter your name for git commits: " GIT_NAME
read -p "Enter your email for git commits: " GIT_EMAIL

# Configure git (local to this repo)
echo "Configuring git (local to this repo)..."
git config user.name "$GIT_NAME"
git config user.email "$GIT_EMAIL"
git config core.autocrlf input
git config init.defaultBranch main

# Create necessary directories
mkdir -p inventory

# Add wiiomm alias to .zshrc
echo "Adding wiiomm alias to .zshrc..."
echo "alias wiiomm=\"$(pwd)/generate_inventory.sh\"" >> ~/.zshrc

# Add SSH key persistence
echo "Adding SSH key persistence to .zshrc..."
echo 'if [ -f ~/.ssh/id_ed25519 ]; then
  eval "$(ssh-agent -s)" > /dev/null
  ssh-add -q ~/.ssh/id_ed25519
fi' >> ~/.zshrc

# Make generate_inventory.sh executable
chmod +x generate_inventory.sh

# Initialize git if not already initialized
if [ ! -d .git ]; then
    echo "Initializing git repository..."
    git init
    git add .
    git commit -m "Initial commit: WIIOMM setup"
fi

# Set up GitHub remote
echo "Setting up GitHub remote..."
echo "Choose authentication method:"
echo "1. SSH (recommended if you have SSH keys configured)"
echo "2. HTTPS with personal access token"
read -p "Enter your choice (1/2): " AUTH_CHOICE

if [ "$AUTH_CHOICE" = "1" ]; then
    # SSH method
    if ! check_repo_exists "$GITHUB_USERNAME" "$GITHUB_REPO" "1"; then
        echo "Repository does not exist. Would you like to create it?"
        read -p "Create repository? (y/n): " CREATE_REPO
        if [ "$CREATE_REPO" = "y" ] || [ "$CREATE_REPO" = "Y" ]; then
            echo "For repository creation, we need a GitHub token with 'repo' scope."
            read -s -p "Enter your GitHub personal access token: " GITHUB_TOKEN; echo
            read -p "Make repository private? (y/n): " IS_PRIVATE
            IS_PRIVATE=$([ "$IS_PRIVATE" = "y" ] || [ "$IS_PRIVATE" = "Y" ] && echo "true" || echo "false")
            
            if create_repo "$GITHUB_USERNAME" "$GITHUB_REPO" "$GITHUB_TOKEN" "$IS_PRIVATE"; then
                echo "Repository created successfully."
            else
                echo "Failed to create repository. Please create it manually on GitHub."
                exit 1
            fi
        else
            echo "Please create the repository manually on GitHub and run the setup again."
            exit 1
        fi
    fi
    git remote add origin "git@github.com:$GITHUB_USERNAME/$GITHUB_REPO.git"
    echo "SSH remote configured."
    echo "Make sure your SSH keys are properly set up with GitHub."
else
    # HTTPS method
    echo "For HTTPS authentication, you'll need a personal access token from GitHub."
    echo "Visit: https://github.com/settings/tokens to create one with 'repo' permissions."
    read -s -p "Enter your GitHub personal access token: " GITHUB_TOKEN; echo
    
    if ! check_repo_exists "$GITHUB_USERNAME" "$GITHUB_REPO" "2" "$GITHUB_TOKEN"; then
        echo "Repository does not exist. Would you like to create it?"
        read -p "Create repository? (y/n): " CREATE_REPO
        if [ "$CREATE_REPO" = "y" ] || [ "$CREATE_REPO" = "Y" ]; then
            read -p "Make repository private? (y/n): " IS_PRIVATE
            IS_PRIVATE=$([ "$IS_PRIVATE" = "y" ] || [ "$IS_PRIVATE" = "Y" ] && echo "true" || echo "false")
            
            if create_repo "$GITHUB_USERNAME" "$GITHUB_REPO" "$GITHUB_TOKEN" "$IS_PRIVATE"; then
                echo "Repository created successfully."
            else
                echo "Failed to create repository. Please create it manually on GitHub."
                exit 1
            fi
        else
            echo "Please create the repository manually on GitHub and run the setup again."
            exit 1
        fi
    fi
    git remote add origin "https://$GITHUB_USERNAME:$GITHUB_TOKEN@github.com/$GITHUB_USERNAME/$GITHUB_REPO.git"
    echo "HTTPS remote configured with your access token."
fi

# Push to GitHub
echo "Pushing to GitHub..."
git branch -M main
git push -u origin main
if [ $? -eq 0 ]; then
    echo "Successfully pushed to GitHub."
else
    echo "Failed to push to GitHub. Please check your credentials and try again."
    exit 1
fi

# Set up cron job
echo ""
echo "=== Setting up cron job ==="
echo "The following cron job will be added to run WIIOMM daily at 09:00:"
echo "0 9 * * * $(pwd)/generate_inventory.sh >> $(pwd)/inventory/cron_log.txt 2>&1"
echo ""

read -p "Would you like to add this cron job now? (y/n): " ADD_CRON

if [ "$ADD_CRON" = "y" ] || [ "$ADD_CRON" = "Y" ]; then
    # Add cron job
    (crontab -l 2>/dev/null; echo "0 9 * * * $(pwd)/generate_inventory.sh >> $(pwd)/inventory/cron_log.txt 2>&1") | crontab -
    echo "Cron job added. WIIOMM will run daily at 09:00."
else
    echo "Cron job not added. You can add it later with: crontab -e"
    echo "Suggested cron entry: 0 9 * * * $(pwd)/generate_inventory.sh >> $(pwd)/inventory/cron_log.txt 2>&1"
fi

# Create initial inventory
echo "Creating initial inventory..."
./generate_inventory.sh

# Get repository URL
REPO_URL=$(get_repo_url "$GITHUB_USERNAME" "$GITHUB_REPO" "$AUTH_CHOICE")

echo ""
echo "=== Setup Complete ==="
echo "1. Git configured with your name and email"
echo "2. WIIOMM alias has been added to your .zshrc"
echo "3. SSH key persistence has been configured"
echo "4. Git repository has been initialized"
echo "5. GitHub remote has been configured"
echo "6. Initial inventory has been created"
echo ""
echo "Your repository is available at:"
echo "🌐 $REPO_URL"
echo ""
echo "Please restart your terminal or run 'source ~/.zshrc' to use the wiiomm command."
echo "You can then run 'wiiomm' to generate a new inventory at any time." 