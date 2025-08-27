#!/bin/bash

# Context7 Prompt Assistant Deployment Script
# This script automates the deployment of the Prompt Assistant LWC app

set -e

echo "🚀 Starting Context7 Prompt Assistant Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Salesforce CLI is installed
check_sf_cli() {
    print_status "Checking Salesforce CLI installation..."
    if ! command -v sf &> /dev/null; then
        print_error "Salesforce CLI is not installed. Please install it first."
        echo "Visit: https://developer.salesforce.com/tools/sfdxcli"
        exit 1
    fi
    print_success "Salesforce CLI is installed"
}

# Check if we're in a Salesforce DX project
check_project_structure() {
    print_status "Checking project structure..."
    if [ ! -f "sfdx-project.json" ] && [ ! -f "sf-project.json" ]; then
        print_error "Not in a Salesforce DX project. Please run this script from the project root."
        exit 1
    fi
    print_success "Project structure is valid"
}

# Authenticate with Salesforce org
authenticate_org() {
    print_status "Authenticating with Salesforce org..."
    if ! sf org display --target-org default 2>/dev/null; then
        print_warning "No default org found. Please authenticate."
        sf org login web --set-default-dev-hub --alias default
    else
        print_success "Already authenticated with org: $(sf org display --target-org default --json | jq -r '.result.username')"
    fi
}

# Deploy metadata to org
deploy_metadata() {
    print_status "Deploying metadata to Salesforce org..."
    
    # Deploy the project
    if sf project deploy start; then
        print_success "Metadata deployed successfully"
    else
        print_error "Deployment failed"
        exit 1
    fi
}

# Assign permissions
assign_permissions() {
    print_status "Setting up permissions..."
    
    # Create a permission set for the app
    cat > force-app/main/default/permissionsets/PromptAssistant.permissionset-meta.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>Permissions for Context7 Prompt Assistant app</description>
    <hasActivationRequired>false</hasActivationRequired>
    <label>Prompt Assistant</label>
    <tabSettings>
        <tab>Prompt_Assistant</tab>
        <visibility>Visible</visibility>
    </tabSettings>
    <userPermissions>
        <enabled>true</enabled>
        <name>ApiEnabled</name>
    </userPermissions>
    <userPermissions>
        <enabled>true</enabled>
        <name>ExecuteAnonymous</name>
    </userPermissions>
</PermissionSet>
EOF

    print_success "Permission set created"
}

# Run tests
run_tests() {
    print_status "Running tests..."
    
    # Run Apex tests
    if sf apex run test --class-names PromptAssistantController,PromptTemplateController; then
        print_success "Tests passed"
    else
        print_warning "Some tests failed - check the output above"
    fi
}

# Create scratch org (optional)
create_scratch_org() {
    read -p "Do you want to create a scratch org for testing? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Creating scratch org..."
        
        # Create scratch org
        if sf org create scratch --definition-file config/project-scratch-def.json --alias prompt-assistant-scratch; then
            print_success "Scratch org created successfully"
            
            # Deploy to scratch org
            if sf project deploy start --target-org prompt-assistant-scratch; then
                print_success "Metadata deployed to scratch org"
                
                # Open scratch org
                sf org open --target-org prompt-assistant-scratch
            else
                print_error "Deployment to scratch org failed"
            fi
        else
            print_error "Failed to create scratch org"
        fi
    fi
}

# Show post-deployment instructions
show_instructions() {
    echo
    print_success "Deployment completed successfully!"
    echo
    echo "📋 Next Steps:"
    echo "1. Navigate to your Salesforce org"
    echo "2. Look for the 'Prompt Assistant' tab in the App Launcher"
    echo "3. If the tab is not visible, check your user permissions"
    echo "4. Assign the 'Prompt Assistant' permission set to your user"
    echo
    echo "🔧 Configuration Required:"
    echo "1. Set up Context7 MCP API credentials in Named Credentials"
    echo "2. Configure Custom Metadata for API settings"
    echo "3. Update PromptAssistantController.getContext7ApiKey() method"
    echo
    echo "📚 Documentation:"
    echo "- Read the README.md file for detailed setup instructions"
    echo "- Check the component documentation in force-app/main/default/lwc/"
    echo "- Review the Apex class documentation in force-app/main/default/classes/"
    echo
    echo "🎯 Testing:"
    echo "1. Open the Prompt Assistant tab"
    echo "2. Try asking: 'Create a lead qualification prompt'"
    echo "3. Test the Context7 integration by mentioning libraries"
    echo "4. Save a template and verify the export functionality"
}

# Main deployment flow
main() {
    echo "Context7 Prompt Assistant - Deployment Script"
    echo "=============================================="
    echo
    
    check_sf_cli
    check_project_structure
    authenticate_org
    assign_permissions
    deploy_metadata
    run_tests
    show_instructions
}

# Run main function
main "$@"
