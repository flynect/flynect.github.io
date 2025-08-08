#!/bin/bash

# Jekyll GitHub Pages Deploy Script
# This script builds Jekyll site and deploys to GitHub Pages

set -e  # Exit on any error

# Configuration - Update these variables
GITHUB_USERNAME="flynect"
REPO_NAME="flynect.github.io"
BRANCH_NAME="main"  # Branch for GitHub Pages
SOURCE_BRANCH="main"    # Your source branch (main/master)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository. Please run this script from your Jekyll project root."
        exit 1
    fi
}

# Check if Jekyll is installed
check_jekyll() {
    if ! command -v jekyll &> /dev/null; then
        log_error "Jekyll is not installed. Please install Jekyll first:"
        echo "gem install jekyll bundler"
        exit 1
    fi
}

# Check if required gems are installed
install_dependencies() {
    log_info "Installing dependencies..."
    if [ -f "Gemfile" ]; then
        bundle install
    else
        log_warning "No Gemfile found. Make sure all required gems are installed."
    fi
}

# Clean previous builds
clean_build() {
    log_info "Cleaning previous builds..."
    if [ -d "_site" ]; then
        rm -rf _site
    fi
}

# Build Jekyll site
build_site() {
    log_info "Building Jekyll site..."
    
    # Set Jekyll environment to production for GitHub Pages
    JEKYLL_ENV=production bundle exec jekyll build --destination _site
    
    if [ $? -eq 0 ]; then
        log_success "Jekyll site built successfully"
    else
        log_error "Jekyll build failed"
        exit 1
    fi
}

# Deploy to GitHub Pages
deploy_to_github() {
    log_info "Deploying to GitHub Pages..."
    
    # Navigate to _site directory
    cd _site
    
    # Initialize git if not already initialized
    if [ ! -d ".git" ]; then
        git init
        git config user.name "$(git config --global user.name)"
        git config user.email "$(git config --global user.email)"
    fi
    
    # Add remote if it doesn't exist
    if ! git remote get-url origin > /dev/null 2>&1; then
        git remote add origin "git@github.com:${GITHUB_USERNAME}/${REPO_NAME}.git"
    fi
    
    # Add all files
    git add -A
    
    # Check if there are changes to commit
    if git diff --staged --quiet; then
        log_warning "No changes to deploy"
        cd ..
        return
    fi
    
    # Commit changes
    COMMIT_MESSAGE="Deploy site - $(date '+%Y-%m-%d %H:%M:%S')"
    git commit -m "$COMMIT_MESSAGE"
    
    # Push to gh-pages branch
    log_info "Pushing to ${BRANCH_NAME} branch..."
    git push -f origin HEAD:${BRANCH_NAME}
    
    if [ $? -eq 0 ]; then
        log_success "Successfully deployed to GitHub Pages!"
        log_info "Your site should be available at: git@github.com:${GITHUB_USERNAME}/${REPO_NAME}.git"
    else
        log_error "Failed to push to GitHub Pages"
        cd ..
        exit 1
    fi
    
    # Return to project root
    cd ..
}

# Create .nojekyll file to prevent GitHub from processing with Jekyll again
create_nojekyll() {
    if [ ! -f "_site/.nojekyll" ]; then
        touch _site/.nojekyll
        log_info "Created .nojekyll file"
    fi
}

# Main execution
main() {
    log_info "Starting Jekyll GitHub Pages deployment..."
    
    # Pre-flight checks
    check_git_repo
    check_jekyll
    
    # Build process
    install_dependencies
    clean_build
    build_site
    create_nojekyll
    
    # Deploy
    deploy_to_github
    
    log_success "Deployment completed successfully!"
}

# Help function
show_help() {
    echo "Jekyll GitHub Pages Deploy Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help     Show this help message"
    echo "  -c, --clean    Clean build only (don't deploy)"
    echo "  -b, --build    Build only (don't deploy)"
    echo ""
    echo "Before using this script:"
    echo "1. Update GITHUB_USERNAME and REPO_NAME variables at the top of the script"
    echo "2. Make sure you have push access to the repository"
    echo "3. Ensure Jekyll and required gems are installed"
    echo ""
    echo "The script will:"
    echo "1. Install dependencies (bundle install)"
    echo "2. Build Jekyll site (_site folder)"
    echo "3. Deploy to gh-pages branch on GitHub"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -c|--clean)
        log_info "Cleaning build directory..."
        clean_build
        log_success "Clean completed"
        exit 0
        ;;
    -b|--build)
        log_info "Building Jekyll site..."
        check_jekyll
        install_dependencies
        clean_build
        build_site
        create_nojekyll
        log_success "Build completed"
        exit 0
        ;;
    "")
        main
        ;;
    *)
        log_error "Unknown option: $1"
        echo "Use -h or --help for usage information"
        exit 1
        ;;
esac