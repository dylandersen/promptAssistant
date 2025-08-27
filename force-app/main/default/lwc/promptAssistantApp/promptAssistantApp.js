import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Version: 1.0.1 - Added avatar support and footer improvements

export default class PromptAssistantApp extends LightningElement {
    @track generatedPrompt = '';
    @track isGenerating = false;
    @track context7Status = {
        isConnected: false,
        lastActivity: null,
        libraryCount: 0
    };

    // Handle prompt generation from chat interface
    handlePromptGenerated(event) {
        const { prompt } = event.detail;
        this.generatedPrompt = prompt;
    }

    // Handle Context7 library resolution
    handleContext7Resolve(event) {
        const libraryData = event.detail;
        this.context7Status.libraryCount++;
        this.context7Status.lastActivity = new Date().toISOString();
        
        console.log('Context7 Library Resolved:', libraryData);
    }

    // Handle Context7 documentation retrieval
    handleContext7GetDocs(event) {
        const docsData = event.detail;
        this.context7Status.lastActivity = new Date().toISOString();
        
        console.log('Context7 Documentation Retrieved:', docsData);
    }

    // Handle template save
    handleSaveTemplate(event) {
        // Handle template saving logic
        console.log('Template saved:', event.detail);
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

    // Lifecycle hook for initialization
    connectedCallback() {
        // Initialize Context7 MCP connection
        this.initializeContext7();
    }

    // Initialize Context7 MCP services
    async initializeContext7() {
        try {
            // Simulate Context7 MCP connection
            this.context7Status.isConnected = true;
            console.log('Context7 MCP initialized');
        } catch (error) {
            console.error('Context7 MCP initialization failed:', error);
            this.showToast('Error', 'Failed to initialize Context7 MCP', 'error');
        }
    }
}
