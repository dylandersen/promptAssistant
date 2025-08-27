import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class MessageItem extends LightningElement {
    @api message;

    // Computed properties for message styling
    get messageClass() {
        const baseClass = 'message';
        const typeClass = `message-${this.message.type}`;
        return `${baseClass} ${typeClass}`;
    }

    get messageIcon() {
        switch (this.message.type) {
            case 'user':
                return 'utility:user';
            case 'assistant':
                return 'utility:bot';
            case 'error':
                return 'utility:error';
            default:
                return 'utility:chat';
        }
    }

    get messageTypeLabel() {
        switch (this.message.type) {
            case 'user':
                return 'You';
            case 'assistant':
                return 'Assistant';
            case 'error':
                return 'Error';
            default:
                return 'System';
        }
    }

    get formattedTime() {
        if (!this.message.timestamp) return '';
        
        const date = new Date(this.message.timestamp);
        return date.toLocaleTimeString([], { 
            hour: '2-digit', 
            minute: '2-digit' 
        });
    }

    get isUserMessage() {
        return this.message.type === 'user';
    }

    get isAssistantMessage() {
        return this.message.type === 'assistant';
    }

    get isCodeBlock() {
        return this.message.content && 
               (this.message.content.includes('```') || 
                this.message.content.includes('{') && this.message.content.includes('}'));
    }

    get formattedContent() {
        if (!this.isCodeBlock) return this.message.content;
        
        // Simple code formatting - in production, use a proper syntax highlighter
        return this.message.content
            .replace(/```(\w+)?/g, '<pre><code>')
            .replace(/```/g, '</code></pre>')
            .replace(/\n/g, '<br>');
    }

    get hasContext7Data() {
        return this.message.metadata && 
               this.message.metadata.context7Libraries && 
               this.message.metadata.context7Libraries.length > 0;
    }

    get showActions() {
        return this.message.type !== 'error';
    }

    // Event handlers
    handleCopy() {
        navigator.clipboard.writeText(this.message.content).then(() => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Copied!',
                message: 'Message copied to clipboard',
                variant: 'success'
            }));
        }).catch(() => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Failed to copy message',
                variant: 'error'
            }));
        });
    }

    handleEdit() {
        this.dispatchEvent(new CustomEvent('messageaction', {
            detail: {
                action: 'edit',
                messageId: this.message.id
            }
        }));
    }

    handleRegenerate() {
        this.dispatchEvent(new CustomEvent('messageaction', {
            detail: {
                action: 'regenerate',
                messageId: this.message.id
            }
        }));
    }

    handleSuggestionClick(event) {
        const suggestion = event.currentTarget.dataset.suggestion;
        this.dispatchEvent(new CustomEvent('suggestionselected', {
            detail: { suggestion }
        }));
    }
}
