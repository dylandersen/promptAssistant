import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PromptTemplateForm extends LightningElement {
    @api promptText = '';

    
    @track templateName = '';
    @track templateDescription = '';
    @track promptContent = '';
    @track templateCategory = '';
    @track templateVariables = [];
    @track showPreview = false;
    @track isFormValid = false;

    // Category options for dropdown
    categoryOptions = [
        { label: 'Sales', value: 'sales' },
        { label: 'Customer Service', value: 'customer-service' },
        { label: 'Marketing', value: 'marketing' },
        { label: 'Data Analysis', value: 'data-analysis' },
        { label: 'Lead Qualification', value: 'lead-qualification' },
        { label: 'Follow-up', value: 'follow-up' },
        { label: 'Onboarding', value: 'onboarding' },
        { label: 'Training', value: 'training' },
        { label: 'General', value: 'general' }
    ];

    // Lifecycle hook to initialize form
    connectedCallback() {
        this.initializeForm();
    }

    // Watch for changes in promptText prop
    renderedCallback() {
        if (this.promptText && !this.promptContent) {
            this.promptContent = this.promptText;
            this.validateForm();
        }
        
        // Adjust textarea height after rendering
        this.adjustTextareaHeight();
    }

    // Initialize form with default values
    initializeForm() {
        this.templateName = '';
        this.templateDescription = '';
        this.promptContent = this.promptText || '';
        this.templateCategory = '';
        this.templateVariables = [];
        this.validateForm();
    }

    // Form event handlers
    handleTemplateNameChange(event) {
        this.templateName = event.target.value;
        this.validateForm();
    }

    handleDescriptionChange(event) {
        this.templateDescription = event.target.value;
        this.validateForm();
    }

    handlePromptContentChange(event) {
        this.promptContent = event.target.value;
        this.validateForm();
        this.extractVariables();
        this.adjustTextareaHeight();
    }

    handleCategoryChange(event) {
        this.templateCategory = event.target.value;
        this.validateForm();
    }



    // Extract variables from prompt content
    extractVariables() {
        if (!this.promptContent) return;

        const variablePattern = /\{\{(\w+)\}\}/g;
        const variables = [];
        let match;

        while ((match = variablePattern.exec(this.promptContent)) !== null) {
            const varName = match[1];
            if (!variables.find(v => v.name === varName)) {
                variables.push({
                    id: `var_${Date.now()}_${variables.length}`,
                    name: varName,
                    description: ''
                });
            }
        }

        // Only add new variables, don't overwrite existing ones
        variables.forEach(newVar => {
            if (!this.templateVariables.find(existing => existing.name === newVar.name)) {
                this.templateVariables = [...this.templateVariables, newVar];
            }
        });
    }

    // Form validation
    validateForm() {
        this.isFormValid = !!(
            this.templateName.trim() &&
            this.promptContent.trim()
        );
    }

    // Copy template content to clipboard
    async handleCopyTemplate() {
        if (!this.isFormValid) {
            this.showToast('Error', 'Please fill in all required fields', 'error');
            return;
        }

        try {
            // Format the template content for copying
            const templateText = this.formatTemplateForCopy();
            
            // Copy to clipboard
            if (navigator.clipboard && navigator.clipboard.writeText) {
                await navigator.clipboard.writeText(templateText);
            } else {
                // Fallback for older browsers
                const textArea = document.createElement('textarea');
                textArea.value = templateText;
                document.body.appendChild(textArea);
                textArea.select();
                document.execCommand('copy');
                document.body.removeChild(textArea);
            }
            
            this.showToast('Success', 'Template content copied to clipboard!', 'success');
            
            // Dispatch event to parent
            this.dispatchEvent(new CustomEvent('templatecopied', {
                detail: {
                    templateName: this.templateName,
                    templateContent: templateText
                }
            }));

        } catch (error) {
            console.error('Error copying template:', error);
            this.showToast('Error', 'Failed to copy template to clipboard', 'error');
        }
    }
    
    // Format template content for copying
    formatTemplateForCopy() {
        const variables = this.templateVariables.length > 0 
            ? this.templateVariables.map(v => `- ${v.name}${v.description ? ': ' + v.description : ''}`).join('\n')
            : 'No variables detected';
            
        return `=== PROMPT TEMPLATE ===
Name: ${this.templateName}
Description: ${this.templateDescription || 'No description provided'}
Category: ${this.templateCategory || 'General'}

=== PROMPT CONTENT ===
${this.promptContent}

=== VARIABLES ===
${variables}

=== INSTRUCTIONS ===
1. Go to Setup > Prompt Builder (or use the "Open Prompt Builder" button)
2. Click "New Prompt Template"  
3. Paste the prompt content from above
4. Configure the template name, description, and variables as listed
5. Set the category and save your template`;
    }
    
    // Open Prompt Builder in Setup
    handleOpenPromptBuilder() {
        const setupUrl = `/lightning/setup/EinsteinPromptStudio/home`;
        window.open(setupUrl, '_blank');
        this.showToast('Info', 'Opening Prompt Builder in a new tab', 'info');
    }
    


    // Preview functionality
    handlePreviewTemplate() {
        if (!this.templateName || !this.promptContent) {
            this.showToast('Error', 'Please fill in template name and content for preview', 'error');
            return;
        }
        this.showPreview = true;
    }

    handleClosePreview() {
        this.showPreview = false;
    }

    // Reset form
    handleResetForm() {
        this.initializeForm();
        this.showToast('Info', 'Form reset to default values', 'info');
    }

    // Utility method for showing toast notifications
    showToast(title, message, variant = 'info') {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    // Computed property for template summary
    get templateSummary() {
        return {
            name: this.templateName || 'Untitled Template',
            description: this.templateDescription || 'No description provided',
            variables: this.templateVariables.length,
            libraries: 0,
            category: this.templateCategory || 'Uncategorized'
        };
    }

    // Computed property for form progress
    get isSavingOrInvalid() {
        return !this.isFormValid;
    }

    get formProgress() {
        const requiredFields = [
            'templateName',
            'promptContent'
        ];
        
        const completedFields = requiredFields.filter(field => {
            switch (field) {
                case 'templateName':
                    return !!this.templateName.trim();
                case 'promptContent':
                    return !!this.promptContent.trim();
                default:
                    return false;
            }
        });

        return Math.round((completedFields.length / requiredFields.length) * 100);
    }

    // Auto-adjust textarea height to fit content
    adjustTextareaHeight() {
        this.template.querySelector('.dynamic-prompt-content lightning-textarea')?.then(textarea => {
            if (textarea) {
                // Reset height to auto to get the correct scrollHeight
                textarea.style.height = 'auto';
                
                // Calculate new height based on content
                const scrollHeight = textarea.scrollHeight;
                const minHeight = 120; // 6 rows minimum
                const newHeight = Math.max(scrollHeight, minHeight);
                
                // Set the new height
                textarea.style.height = `${newHeight}px`;
            }
        });
    }
}
