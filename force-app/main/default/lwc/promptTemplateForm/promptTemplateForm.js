import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PromptTemplateForm extends LightningElement {
    @api promptText = '';
    @api context7Libraries = [];
    
    @track templateName = '';
    @track templateDescription = '';
    @track promptContent = '';
    @track templateCategory = '';
    @track templateVariables = [];
    @track isSaving = false;
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

    // Variable management
    handleVariableChange(event) {
        const index = parseInt(event.target.dataset.index);
        const field = event.target.dataset.field;
        const value = event.target.value;

        this.templateVariables[index][field] = value;
        this.templateVariables = [...this.templateVariables];
    }

    handleAddVariable() {
        const newVariable = {
            id: `var_${Date.now()}`,
            name: '',
            description: ''
        };
        this.templateVariables = [...this.templateVariables, newVariable];
    }

    handleRemoveVariable(event) {
        const index = parseInt(event.target.dataset.index);
        this.templateVariables.splice(index, 1);
        this.templateVariables = [...this.templateVariables];
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
            this.promptContent.trim() &&
            this.templateCategory
        );
    }

    // Save template
    async handleSaveTemplate() {
        if (!this.isFormValid) {
            this.showToast('Error', 'Please fill in all required fields', 'error');
            return;
        }

        this.isSaving = true;

        try {
            const templateData = {
                name: this.templateName,
                description: this.templateDescription,
                content: this.promptContent,
                category: this.templateCategory,
                variables: this.templateVariables,
                context7Libraries: this.context7Libraries,
                createdDate: new Date().toISOString()
            };

            // For demo purposes, generate a mock template ID
            const result = 'TEMPLATE_' + Date.now();
            
            this.showToast('Success', 'Prompt template saved successfully!', 'success');
            
            // Dispatch event to parent
            this.dispatchEvent(new CustomEvent('savetemplate', {
                detail: {
                    templateId: result,
                    templateData: templateData
                }
            }));

            // Reset form
            this.initializeForm();

        } catch (error) {
            console.error('Error saving template:', error);
            this.showToast('Error', error.body?.message || 'Failed to save template', 'error');
        } finally {
            this.isSaving = false;
        }
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
            libraries: this.context7Libraries.length,
            category: this.templateCategory || 'Uncategorized'
        };
    }

    // Computed property for form progress
    get isSavingOrInvalid() {
        return this.isSaving || !this.isFormValid;
    }

    get formProgress() {
        const requiredFields = [
            'templateName',
            'promptContent',
            'templateCategory'
        ];
        
        const completedFields = requiredFields.filter(field => {
            switch (field) {
                case 'templateName':
                    return !!this.templateName.trim();
                case 'promptContent':
                    return !!this.promptContent.trim();
                case 'templateCategory':
                    return !!this.templateCategory;
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
