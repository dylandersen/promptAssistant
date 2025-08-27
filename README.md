# Prompt Assistant - Salesforce LWC App

A comprehensive Lightning Web Component (LWC) application that provides a ChatGPT-style interface for generating effective prompt instructions for Salesforce Prompt Builder's Prompt Templates.

## 🚀 Features

### Core Functionality
- **ChatGPT-Style Interface**: Modern chat interface with "What prompt can I write for you?" as the central interaction
- **Prompt Template Management**: Save, edit, and export prompts to Prompt Builder format
- **SLDS2 Compliant UI**: Modern, responsive design following Salesforce Lightning Design System 2.0
- **Real-time Prompt Generation**: AI-powered prompt creation with intelligent context
- **Variable Detection**: Automatic extraction and management of template variables
- **Template Validation**: Built-in validation and scoring for prompt quality

### Technical Features
- **Responsive Design**: Works seamlessly on desktop, tablet, and mobile devices
- **Event-Driven Architecture**: Clean separation of concerns with proper component communication
- **Security**: Input validation, XSS protection, and secure API handling
- **Extensible**: Modular design supporting future enhancements and integrations
- **Performance**: Optimized rendering and efficient state management

## 📁 Project Structure

```
force-app/main/default/
├── classes/
│   ├── PromptAssistantController.cls          # Prompt generation logic
│   └── PromptTemplateController.cls           # Template management
├── lwc/
│   ├── promptAssistantApp/                    # Main app component
│   │   ├── promptAssistantApp.html
│   │   ├── promptAssistantApp.js
│   │   ├── promptAssistantApp.css
│   │   └── promptAssistantApp.js-meta.xml
│   ├── promptChatInterface/                   # Chat interface component
│   │   ├── promptChatInterface.html
│   │   ├── promptChatInterface.js
│   │   ├── promptChatInterface.css
│   │   └── promptChatInterface.js-meta.xml
│   ├── messageItem/                           # Individual message component
│   │   ├── messageItem.html
│   │   ├── messageItem.js
│   │   ├── messageItem.css
│   │   └── messageItem.js-meta.xml
│   └── promptTemplateForm/                    # Template form component
│       ├── promptTemplateForm.html
│       ├── promptTemplateForm.js
│       ├── promptTemplateForm.css
│       └── promptTemplateForm.js-meta.xml
├── tabs/
│   └── Prompt_Assistant.tab-meta.xml         # Custom tab configuration
└── staticresources/                           # Static resources (if any)
```

## 🛠️ Installation & Setup

### Prerequisites
- Salesforce DX CLI installed
- Salesforce org with API version 64.0+

### Deployment Steps

1. **Clone and Setup Project**
   ```bash
   git clone <repository-url>
   cd dylannewideaaug25
   ```

2. **Authenticate with Salesforce**
   ```bash
   sf org login web
   ```

3. **Deploy to Your Org**
   ```bash
   sf project deploy start
   ```

4. **Assign Permissions**
   - Navigate to Setup > Users > Permission Sets
   - Create a new permission set or edit existing
   - Add the following permissions:
     - Access to Prompt Assistant tab
     - Execute Apex classes
     - Read/Write access to relevant custom objects (if using)

5. **Configure AI Integration (Optional)**
   - For production use, integrate with OpenAI, Anthropic, or Agentforce
   - Update `PromptAssistantController.callAIService()` method
   - Configure Named Credentials for external AI services

## 🔧 Configuration

### AI Integration
The app can integrate with external AI services for enhanced prompt generation. Configure the integration by:

1. **Setting up Named Credentials**
   ```xml
   <!-- Create a Named Credential for OpenAI API -->
   <NamedCredential>
       <fullName>OpenAI_API</fullName>
       <endpoint>https://api.openai.com/v1</endpoint>
       <label>OpenAI API</label>
   </NamedCredential>
   ```

2. **Custom Metadata for API Configuration**
   ```xml
   <!-- Create Custom Metadata Type for AI settings -->
   <CustomObject>
       <fullName>AI_Settings__mdt</fullName>
       <fields>
           <fullName>API_Key__c</fullName>
           <type>Text</type>
           <length>255</length>
       </fields>
   </CustomObject>
   ```

### Prompt Builder Integration
The app is designed to integrate with Salesforce Prompt Builder. Configure the integration by:

1. **Setting up API endpoints** for Prompt Builder
2. **Configuring authentication** for external API calls
3. **Setting up data mapping** between the app and Prompt Builder

## 🎯 Usage Guide

### Getting Started
1. Navigate to the "Prompt Assistant" tab in your Salesforce org
2. You'll see the main chat interface with the question "What prompt can I write for you?"
3. Describe what type of prompt you need (e.g., "Create a lead qualification prompt")
4. The assistant will generate a professional prompt template

### Using Context7 Integration
1. **Library References**: Mention libraries in your query (e.g., "Create a React-based prompt")
2. **Automatic Resolution**: The app will automatically resolve library information
3. **Documentation Context**: Generated prompts will include relevant API patterns

### Template Management
1. **Save Templates**: Use the sidebar form to save generated prompts as templates
2. **Variable Management**: Templates automatically detect and manage variables
3. **Export to Prompt Builder**: Templates can be exported for use in Salesforce Prompt Builder

### Best Practices
- Be specific in your requests for better prompt generation
- Use clear, professional language in your queries
- Review and edit generated prompts before saving
- Leverage Context7 libraries for technical prompts

## 🔒 Security Considerations

### Input Validation
- All user inputs are validated and sanitized
- XSS protection implemented
- SQL injection prevention in Apex controllers

### API Security
- API keys stored securely in Named Credentials
- HTTPS enforced for all external API calls
- Rate limiting implemented for Context7 API calls

### Data Protection
- User data is not stored unless explicitly saved as templates
- Audit logging for template creation and modifications
- Compliance with Salesforce security standards

## 🚀 Extensibility

### Adding New Features
The modular architecture makes it easy to extend:

1. **New Components**: Create new LWC components in the `lwc/` directory
2. **Additional Controllers**: Add new Apex classes for extended functionality
3. **Custom Objects**: Create custom objects for enhanced data storage
4. **External Integrations**: Add new API integrations following the existing pattern

### Customization Points
- **UI Themes**: Modify CSS variables for branding
- **Prompt Templates**: Add new template categories and types
- **AI Services**: Integrate with different AI providers
- **Context7 Libraries**: Add support for additional library types

## 🧪 Testing

### Unit Tests
Run Apex tests:
```bash
sf apex run test --class-names PromptAssistantController,PromptTemplateController
```

### Component Tests
Create Jest tests for LWC components:
```bash
npm test
```

### Integration Tests
Test the full workflow:
1. Generate a prompt
2. Save as template
3. Export to Prompt Builder
4. Validate functionality

## 📊 Monitoring & Analytics

### Debug Logs
Enable debug logging for:
- Context7 API calls
- Prompt generation requests
- Template save operations

### Performance Monitoring
Monitor:
- API response times
- Component rendering performance
- User interaction patterns

## 🤝 Contributing

### Development Workflow
1. Create a feature branch
2. Make changes following the existing code patterns
3. Add tests for new functionality
4. Update documentation
5. Submit a pull request

### Code Standards
- Follow Salesforce Lightning Web Component best practices
- Use SLDS2 design tokens and components
- Implement proper error handling
- Add comprehensive comments

## 📝 API Reference

### PromptAssistantController
- `generatePrompt(String userQuery, String context7Data)` - Generate AI-powered prompts
- `resolveLibrary(String libraryName)` - Resolve library information via Context7 MCP
- `getLibraryDocs(String libraryId, String topic, Integer tokens)` - Retrieve library documentation

### PromptTemplateController
- `savePromptTemplate(String templateData)` - Save prompt templates
- `getPromptTemplates(String category, Integer limitCount)` - Retrieve templates
- `exportToPromptBuilder(String templateId)` - Export to Prompt Builder format
- `validateTemplate(String templateContent)` - Validate template syntax and quality

## 🔮 Future Enhancements

### Planned Features
- **Multi-language Support**: Support for multiple languages in prompt generation
- **Template Sharing**: Collaborative template creation and sharing
- **Advanced Analytics**: Detailed usage analytics and insights
- **Mobile App**: Native mobile application support
- **Enterprise Features**: Advanced security and compliance features

### Integration Roadmap
- **Agentforce**: Direct integration with Salesforce Agentforce
- **Flow Builder**: Integration with Salesforce Flow Builder
- **Process Builder**: Automation workflows for prompt management
- **External AI Providers**: Support for OpenAI, Anthropic, and other providers

## 📞 Support

### Documentation
- [Salesforce LWC Developer Guide](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)
- [SLDS2 Design System](https://www.lightningdesignsystem.com/)
- [Context7 MCP Documentation](https://context7.com/docs)

### Issues & Feedback
- Report bugs through GitHub Issues
- Request features through GitHub Discussions
- Contact support team for enterprise assistance

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Built with ❤️ for the Salesforce community**
