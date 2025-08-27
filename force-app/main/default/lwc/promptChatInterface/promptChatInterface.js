import { LightningElement, track, api } from 'lwc';
import generatePrompt from '@salesforce/apex/PromptAssistantController.generatePrompt';

// Version: 1.0.4 - Simplified template-based approach for better reliability

export default class PromptChatInterface extends LightningElement {
    @api sessionId;
    @track messages = [];
    @track userInput = '';
    @track isGenerating = false;
    @track messageIdCounter = 0;
    @track isInitialized = false;

    // Computed properties for UI state
    get inputPlaceholder() {
        return this.isGenerating 
            ? 'Generating prompt... Please wait...' 
            : 'Describe what prompt you need for Salesforce Prompt Builder...';
    }

    get inputClass() {
        return this.isGenerating ? 'input-disabled' : '';
    }

    get isGeneratingDisabled() {
        return true;
    }

    // Check if content should be formatted (contains markdown-like formatting)
    shouldFormatContent(content) {
        if (!content || typeof content !== 'string') return false;
        
        // Check for common formatting patterns
        const formattingPatterns = [
            /\*\*.*?\*\*/,           // Bold text **text**
            /\*.*?\*/,               // Italic text *text*
            /^[-*+]\s/,              // Bullet points
            /^\d+\.\s/,              // Numbered lists
            /^#{1,6}\s/,             // Headers
            /\n\n/,                  // Double line breaks
            /`.*?`/,                 // Inline code
            /```[\s\S]*?```/         // Code blocks
        ];
        
        return formattingPatterns.some(pattern => pattern.test(content));
    }

    // Format LLM content to preserve formatting
    formatLLMContent(content) {
        if (!content || typeof content !== 'string') return content;
        
        let formatted = content;
        
        // Preserve line breaks and spacing exactly as received
        formatted = formatted.replace(/\n\n/g, '\n\n'); // Keep double line breaks
        formatted = formatted.replace(/\n/g, '\n');     // Keep single line breaks
        
        // Convert markdown-style formatting to readable text
        formatted = formatted.replace(/\*\*(.*?)\*\*/g, '**$1**');  // Keep bold markers
        formatted = formatted.replace(/\*(.*?)\*/g, '*$1*');        // Keep italic markers
        formatted = formatted.replace(/`(.*?)`/g, '`$1`');          // Keep code markers
        
        // Remove the problematic line break after periods - this was causing the issue
        // formatted = formatted.replace(/([.!?])\s*([A-Z])/g, '$1\n\n$2'); // REMOVED THIS LINE
        
        return formatted;
    }



    connectedCallback() {
        // Initialize the component - no DOM manipulation here
        this.isInitialized = true;
    }

    renderedCallback() {
        // Only add welcome message on first render and when DOM is ready
        if (this.messages.length === 0 && this.isInitialized) {
            // Add a small delay to ensure everything is properly rendered
            setTimeout(() => {
                this.addMessage({
                    id: this.getMessageId(),
                    type: 'assistant',
                    content: 'Hello! I\'m your Agentforce-powered prompt assistant. I\'ll help you create effective prompts for Salesforce Prompt Builder using native AI capabilities.',
                    timestamp: new Date().toISOString(),
                    suggestions: [
                        'Create a lead qualification prompt',
                        'Generate a customer service response',
                        'Build a sales follow-up template',
                        'Design a data analysis prompt'
                    ]
                });
            }, 200); // Increased delay for better DOM readiness
        }
    }

    // Handle user input changes
    handleInputChange(event) {
        this.userInput = event.target.value;
    }

    // Handle keyboard events (Enter key)
    handleKeyDown(event) {
        if (event.key === 'Enter' && event.ctrlKey) {
            event.preventDefault();
            this.handleGeneratePrompt();
        }
    }

    // Generate prompt using native Salesforce Models API
    async handleGeneratePrompt() {
        if (!this.userInput.trim()) {
            return;
        }

        const userMessage = {
            id: this.getMessageId(),
            type: 'user',
            content: this.userInput,
            timestamp: new Date().toISOString()
        };

        this.addMessage(userMessage);
        this.isGenerating = true;

        try {
            console.log('Generating prompt for:', this.userInput);
            
            // Generate the prompt using native Salesforce Models API
            const result = await generatePrompt({ 
                userQuery: this.userInput,
                contextData: JSON.stringify({})
            });

            console.log('Models API response:', result);

            if (!result || !result.generatedPrompt) {
                throw new Error('No response received from Models API');
            }

            const assistantMessage = {
                id: this.getMessageId(),
                type: 'assistant',
                content: result.generatedPrompt,
                timestamp: new Date().toISOString(),
                metadata: {
                    confidence: result.confidence,
                    suggestions: result.suggestions
                }
            };

            console.log('Adding assistant message:', assistantMessage);
            this.addMessage(assistantMessage);

            // Dispatch event to parent component
            this.dispatchEvent(new CustomEvent('promptgenerated', {
                detail: {
                    prompt: result.generatedPrompt,
                    userQuery: this.userInput
                }
            }));

        } catch (error) {
            console.error('Error generating prompt:', error);
            let errorMessage = 'Failed to generate prompt';
            
            if (error.body?.message) {
                errorMessage = error.body.message;
            } else if (error.message) {
                errorMessage = error.message;
            }
            
            this.addErrorMessage(errorMessage);
        } finally {
            this.isGenerating = false;
            this.userInput = '';
            this.scrollToBottom();
        }
    }

    // Handle message actions (copy, edit, etc.)
    handleMessageAction(event) {
        const { action, messageId } = event.detail;
        
        switch (action) {
            case 'copy':
                this.copyToClipboard(messageId);
                break;
            case 'edit':
                this.editMessage(messageId);
                break;
            case 'regenerate':
                this.regeneratePrompt(messageId);
                break;
        }
    }

    // Add message to chat
    addMessage(message) {
        console.log('Adding message to chat:', message);
        
        // Create a processed message object with computed properties
        const processedMessage = {
            ...message,
            messageClass: `message message-${message.type}`,
            iconName: message.type === 'user' ? 'utility:user' : 'utility:bot',
            displayName: message.type === 'user' ? 'You' : 'Assistant',
            formattedTime: new Date(message.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
            isFormatted: message.type === 'assistant' && this.shouldFormatContent(message.content),
            formattedContent: message.type === 'assistant' ? this.formatLLMContent(message.content) : null
        };
        
        this.messages = [...this.messages, processedMessage];
        console.log('Updated messages array:', this.messages);
        
        // Scroll to bottom after a short delay to ensure DOM is updated
        setTimeout(() => {
            this.scrollToBottom();
        }, 100);
    }

    // Add error message
    addErrorMessage(errorMessage) {
        const errorMsg = {
            id: this.getMessageId(),
            type: 'error',
            content: errorMessage,
            timestamp: new Date().toISOString()
        };
        this.addMessage(errorMsg);
    }

    // Clear chat
    handleClearChat() {
        this.messages = [];
        this.messageIdCounter = 0;
        
        // Re-add welcome message
        this.addMessage({
            id: this.getMessageId(),
            type: 'assistant',
            content: 'Hello! I\'m your Agentforce-powered prompt assistant. I\'ll help you create effective prompts for Salesforce Prompt Builder using native AI capabilities.',
            timestamp: new Date().toISOString(),
        });
    }

    // Utility methods
    getMessageId() {
        return `msg_${++this.messageIdCounter}_${Date.now()}`;
    }

    scrollToBottom() {
        try {
            const messagesContainer = this.template.querySelector('.messages-container');
            if (messagesContainer && messagesContainer.scrollHeight > 0 && messagesContainer.scrollHeight !== undefined) {
                messagesContainer.scrollTop = messagesContainer.scrollHeight;
            }
        } catch (error) {
            console.warn('Could not scroll to bottom:', error);
        }
    }

    copyToClipboard(messageId) {
        const message = this.messages.find(msg => msg.id === messageId);
        if (message) {
            navigator.clipboard.writeText(message.content);
            // Show success toast (implement toast notification)
        }
    }

    editMessage(messageId) {
        const message = this.messages.find(msg => msg.id === messageId);
        if (message && message.type === 'user') {
            this.userInput = message.content;
        }
    }

    async regeneratePrompt(messageId) {
        const message = this.messages.find(msg => msg.id === messageId);
        if (message && message.type === 'user') {
            this.userInput = message.content;
            await this.handleGeneratePrompt();
        }
    }
}
