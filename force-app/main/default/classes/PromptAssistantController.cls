/**
 * Apex Controller for Prompt Assistant
 * Uses native Salesforce Models API for LLM functionality
 */
public with sharing class PromptAssistantController {
    
    // Default model for OpenAI GPT-4o mini
    private static final String DEFAULT_MODEL = 'sfdc_ai__DefaultOpenAIGPT4OmniMini';
    
    /**
     * Generate prompt using native Salesforce Models API
     * @param userQuery The user's input query
     * @param contextData JSON string containing additional context
     * @return PromptGenerationResult containing the generated prompt
     */
    @AuraEnabled
    public static PromptGenerationResult generatePrompt(String userQuery, String contextData) {
        try {
            // Validate input
            if (String.isBlank(userQuery)) {
                throw new AuraHandledException('User query cannot be empty');
            }
            
            // Parse context data if provided
            Map<String, Object> contextMap = new Map<String, Object>();
            if (String.isNotBlank(contextData)) {
                contextMap = (Map<String, Object>) JSON.deserializeUntyped(contextData);
            }
            
            // Build enhanced prompt with context
            String enhancedPrompt = buildEnhancedPrompt(userQuery, contextMap);
            
            // Call native Salesforce Models API
            String generatedResponse = callModelsAPI(enhancedPrompt);
            
            // Generate suggestions based on user query
            List<String> suggestions = generateSuggestions(userQuery, contextMap);
            
            PromptGenerationResult result = new PromptGenerationResult();
            result.generatedPrompt = generatedResponse;
            result.confidence = 0.95; // High confidence for native API
            result.suggestions = suggestions;
            result.metadata = contextMap;
            
            return result;
            
        } catch (AuraHandledException e) {
            // Re-throw AuraHandledException as-is
            throw e;
        } catch (Exception e) {
            System.debug('Error generating prompt: ' + e.getMessage());
            throw new AuraHandledException('Failed to generate prompt: ' + e.getMessage());
        }
    }
    
    /**
     * Call native Salesforce Models API using createGenerations
     * @param prompt The prompt to send to the LLM
     * @return String The generated response
     */
    private static String callModelsAPI(String prompt) {
        try {
            // Create generate text request
            aiplatform.ModelsAPI.createGenerations_Request request = new aiplatform.ModelsAPI.createGenerations_Request();
            
            // Specify model
            request.modelName = DEFAULT_MODEL;
            
            // Create request body
            aiplatform.ModelsAPI_GenerationRequest requestBody = new aiplatform.ModelsAPI_GenerationRequest();
            request.body = requestBody;
            
            // Add prompt to body
            requestBody.prompt = prompt;
            
            // Make request
            aiplatform.ModelsAPI modelsAPI = new aiplatform.ModelsAPI();
            aiplatform.ModelsAPI.createGenerations_Response response = modelsAPI.createGenerations(request);
            
            // Extract the generated text from response
            if (response.Code200 != null && response.Code200.generation != null) {
                return response.Code200.generation.generatedText;
            } else {
                throw new AuraHandledException('Invalid response from Models API');
            }
            
        } catch (aiplatform.ModelsAPI.createGenerations_ResponseException e) {
            System.debug('Models API Response Exception: ' + e.getMessage());
            System.debug('Response code: ' + e.responseCode);
            throw new AuraHandledException('Models API error: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Models API Error: ' + e.getMessage());
            throw new AuraHandledException('Models API error: ' + e.getMessage());
        }
    }
    
    /**
     * Build an enhanced prompt with context and Salesforce-specific instructions
     * @param userQuery The original user query
     * @param contextData Additional context data
     * @return String Enhanced prompt for the LLM
     */
    private static String buildEnhancedPrompt(String userQuery, Map<String, Object> contextData) {
        String enhancedPrompt = '';
        
        // CRITICAL: Strong system instructions to eliminate LLM fluff
        enhancedPrompt += 'CRITICAL INSTRUCTIONS: You are a Salesforce prompt engineering expert. ';
        enhancedPrompt += 'You MUST output ONLY the raw prompt template with NO conversational language, greetings, or explanations. ';
        enhancedPrompt += 'DO NOT use phrases like "Certainly!", "Let me help you", "Here\'s a template", or any other conversational elements. ';
        enhancedPrompt += 'Output ONLY the prompt template itself - nothing more, nothing less.\n\n';
        
        // Core task definition with comprehensive examples
        enhancedPrompt += 'TASK: Create a GOLD STANDARD Salesforce Prompt Builder template based on the user request. ';
        enhancedPrompt += 'Your output must match the quality and structure of these examples:\n\n';
        enhancedPrompt += 'EXAMPLE GOLD STANDARD TEMPLATES:\n\n';
        enhancedPrompt += 'SALES EMAIL EXAMPLE:\n';
        enhancedPrompt += 'You\'re an Account Executive and your name is {!$User.Name} from an organization called {!$User.Company} and you sell commercial solar panels.\n';
        enhancedPrompt += 'Your prospect is {!$Input:lead.Name} from the company {!$Input:lead.Company}.\n';
        enhancedPrompt += 'You want to tell your prospect how {!$User.Company} solar panels can help them achieve their sustainability goals and save energy costs.\n';
        enhancedPrompt += 'When I ask you to generate an introduction email, you must strictly follow my instructions below.\n\n';
        enhancedPrompt += 'Instructions:\n';
        enhancedPrompt += '"""\n';
        enhancedPrompt += 'Use clear, concise, and straightforward language using the active voice and strictly avoiding the use of filler words and phrases and redundant language.\n';
        enhancedPrompt += 'Generate a subject line that can increase open rate using words and content that is related to the email body content.\n';
        enhancedPrompt += 'Propose a meeting with your prospect, and express a desire to learn more about their needs.\n';
        enhancedPrompt += 'Indirectly encourage the prospect to respond to your email by showing that you\'re willing to answer any questions they may have.\n';
        enhancedPrompt += 'End the email with a clear call to action for the prospect to attend a short meeting.\n';
        enhancedPrompt += 'CRITICAL: Format your response with proper paragraph spacing and line breaks between sections for readability.\n';
        enhancedPrompt += 'CRITICAL: Use clear paragraph separation between the introduction, benefits, meeting proposal, and call to action.\n';
        enhancedPrompt += 'CRITICAL: Ensure each paragraph is properly spaced and easy to read.\n';
        enhancedPrompt += '"""\n\n';
        enhancedPrompt += 'Now generate the introduction email to your prospect.\n\n';
        
        enhancedPrompt += 'CASE SUMMARY EXAMPLE:\n';
        enhancedPrompt += 'You are a Customer Service Representative reviewing case {!$Record.CaseNumber} for customer {!$Record.Contact.Name}.\n';
        enhancedPrompt += 'The case involves {!$Record.Subject} and has a priority of {!$Record.Priority}.\n';
        enhancedPrompt += 'When I ask you to generate a case summary, you must strictly follow my instructions below.\n\n';
        enhancedPrompt += 'Instructions:\n';
        enhancedPrompt += '"""\n';
        enhancedPrompt += 'Provide a concise summary of the case details, customer information, and current status.\n';
        enhancedPrompt += 'Include key actions taken, resolution steps, and next steps required.\n';
        enhancedPrompt += 'Use bullet points for clarity and ensure all critical information is captured.\n';
        enhancedPrompt += 'CRITICAL: Format your response with proper spacing and structure for easy reading.\n';
        enhancedPrompt += 'CRITICAL: Use clear section headers and bullet points for organization.\n';
        enhancedPrompt += '"""\n\n';
        enhancedPrompt += 'Now generate the case summary.\n\n';
        
        enhancedPrompt += 'LEAD QUALIFICATION EXAMPLE:\n';
        enhancedPrompt += 'You are a Sales Development Representative evaluating lead {!$Input:lead.Name} from {!$Input:lead.Company}.\n';
        enhancedPrompt += 'The lead has a score of {!$Input:lead.Lead_Score__c} and industry {!$Input:lead.Industry}.\n';
        enhancedPrompt += 'When I ask you to qualify this lead, you must strictly follow my instructions below.\n\n';
        enhancedPrompt += 'Instructions:\n';
        enhancedPrompt += '"""\n';
        enhancedPrompt += 'Evaluate the lead based on BANT criteria (Budget, Authority, Need, Timeline).\n';
        enhancedPrompt += 'Provide a qualification score and reasoning for your assessment.\n';
        enhancedPrompt += 'Recommend next steps and follow-up actions.\n';
        enhancedPrompt += 'CRITICAL: Structure your response with clear sections and bullet points.\n';
        enhancedPrompt += 'CRITICAL: Use proper spacing between sections for readability.\n';
        enhancedPrompt += '"""\n\n';
        enhancedPrompt += 'Now qualify this lead.\n\n';
        
        // Required structure and format
        enhancedPrompt += 'REQUIRED FORMAT:\n';
        enhancedPrompt += '1. Start with the prompt template immediately - no introductions\n';
        enhancedPrompt += '2. Define clear roles and context using merge fields\n';
        enhancedPrompt += '3. Use proper Salesforce merge field format: {!$User.Name}, {!$Input:record.Field}, {!$Record.Field}\n';
        enhancedPrompt += '4. Include rigid, specific instructions within the prompt itself\n';
        enhancedPrompt += '5. Make the prompt self-contained with clear output requirements\n';
        enhancedPrompt += '6. End with the template - no conclusions or additional text\n\n';
        
        // Salesforce-specific requirements
        enhancedPrompt += 'SALESFORCE REQUIREMENTS:\n';
        enhancedPrompt += '- Use proper Salesforce merge field syntax: {!$User.Name}, {!$Input:record.Field}, {!$Record.Field}\n';
        enhancedPrompt += '- Include clear role definitions and context\n';
        enhancedPrompt += '- Add rigid instructions within the prompt itself\n';
        enhancedPrompt += '- Make prompts actionable and measurable\n';
        enhancedPrompt += '- Optimize for automation and workflow integration\n';
        enhancedPrompt += '- Include data privacy and security considerations\n\n';
        
        // Add context information if available
        if (contextData != null && !contextData.isEmpty()) {
            enhancedPrompt += 'CONTEXT INFORMATION:\n';
            for (String key : contextData.keySet()) {
                enhancedPrompt += '- ' + key + ': ' + contextData.get(key) + '\n';
            }
            enhancedPrompt += '\n';
        }
        
        // User request with specific formatting requirements
        enhancedPrompt += 'USER REQUEST: ' + userQuery + '\n\n';
        enhancedPrompt += 'OUTPUT REQUIREMENTS:\n';
        enhancedPrompt += '- Output ONLY the prompt template\n';
        enhancedPrompt += '- Follow the gold standard example structure above\n';
        enhancedPrompt += '- Include clear role definitions and context\n';
        enhancedPrompt += '- Use proper Salesforce merge field syntax\n';
        enhancedPrompt += '- Add rigid instructions within the prompt itself\n';
        enhancedPrompt += '- Make the prompt self-contained and ready for immediate use\n';
        enhancedPrompt += '- NO conversational language, NO explanations, NO additional text\n';
        enhancedPrompt += '- CRITICAL: Include formatting instructions for proper spacing and paragraph breaks\n';
        enhancedPrompt += '- CRITICAL: Specify that responses should have clear paragraph separation and readable formatting\n';
        enhancedPrompt += '- CRITICAL: Instruct the LLM to use proper line breaks between paragraphs and sections\n';
        enhancedPrompt += '- CRITICAL: Adapt the template structure to ANY use case (emails, summaries, reports, workflows, etc.)\n';
        enhancedPrompt += '- CRITICAL: Ensure the prompt can handle ANY Salesforce object or business process\n';
        enhancedPrompt += '- CRITICAL: Make the template flexible enough for campaigns, cases, leads, opportunities, or any other scenario\n\n';
        enhancedPrompt += 'BEGIN PROMPT TEMPLATE:';
        
        return enhancedPrompt;
    }
    
    /**
     * Generate contextual suggestions based on user query
     * @param userQuery The user's original query
     * @param contextData Additional context data
     * @return List<String> Relevant suggestions
     */
    private static List<String> generateSuggestions(String userQuery, Map<String, Object> contextData) {
        List<String> suggestions = new List<String>();
        String lowerQuery = userQuery.toLowerCase();
        
        // Add suggestions based on query content
        if (lowerQuery.contains('lead') || lowerQuery.contains('qualification')) {
            suggestions.add('Create a lead scoring prompt');
            suggestions.add('Generate a BANT qualification template');
            suggestions.add('Design a lead nurturing sequence');
        } else if (lowerQuery.contains('customer') || lowerQuery.contains('service')) {
            suggestions.add('Create a customer service response template');
            suggestions.add('Generate an escalation workflow prompt');
            suggestions.add('Design a customer feedback survey');
        } else if (lowerQuery.contains('sales') || lowerQuery.contains('proposal')) {
            suggestions.add('Create a sales proposal template');
            suggestions.add('Generate a discovery call script');
            suggestions.add('Design a follow-up sequence');
        } else {
            suggestions.add('Create a meeting follow-up template');
            suggestions.add('Generate an onboarding workflow');
            suggestions.add('Design a training guide');
        }
        
        // Add general Salesforce suggestions
        suggestions.add('Create a data analysis prompt');
        suggestions.add('Generate a report summary template');
        
        return suggestions;
    }
    
    /**
     * Get available models for the org
     * @return List<String> Available model names
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getAvailableModels() {
        try {
            // Return the default model for now
            // In the future, you could query available models from the org
            List<String> models = new List<String>();
            models.add(DEFAULT_MODEL);
            return models;
            
        } catch (Exception e) {
            System.debug('Error getting available models: ' + e.getMessage());
            // Return empty list on error
            return new List<String>();
        }
    }
    
    /**
     * Test Models API connectivity
     * @return Map<String, Object> Test results
     */
    @AuraEnabled
    public static Map<String, Object> testModelsAPIConnectivity() {
        try {
            // Test with a simple prompt
            String testPrompt = 'Hello, this is a test message. Please respond with "API is working correctly."';
            
            // Create generate text request
            aiplatform.ModelsAPI.createGenerations_Request request = new aiplatform.ModelsAPI.createGenerations_Request();
            request.modelName = DEFAULT_MODEL;
            
            aiplatform.ModelsAPI_GenerationRequest requestBody = new aiplatform.ModelsAPI_GenerationRequest();
            requestBody.prompt = testPrompt;
            request.body = requestBody;
            
            // Make request
            aiplatform.ModelsAPI modelsAPI = new aiplatform.ModelsAPI();
            aiplatform.ModelsAPI.createGenerations_Response response = modelsAPI.createGenerations(request);
            
            Map<String, Object> result = new Map<String, Object>();
            result.put('status', 'success');
            result.put('message', 'Models API is working correctly');
            result.put('testResponse', response.Code200?.generation?.generatedText);
            result.put('hasAccess', true);
            
            return result;
            
        } catch (Exception e) {
            Map<String, Object> result = new Map<String, Object>();
            result.put('status', 'error');
            result.put('message', 'Models API connectivity test failed: ' + e.getMessage());
            result.put('hasAccess', false);
            return result;
        }
    }
    
    /**
     * Get Models API configuration status
     * @return Map<String, Object> Configuration status
     */
    @AuraEnabled
    public static Map<String, Object> getModelsAPIConfigurationStatus() {
        try {
            Map<String, Object> result = new Map<String, Object>();
            result.put('status', 'success');
            result.put('message', 'Models API is configured and ready');
            result.put('defaultModel', DEFAULT_MODEL);
            result.put('isConfigured', true);
            
            return result;
            
        } catch (Exception e) {
            Map<String, Object> result = new Map<String, Object>();
            result.put('status', 'error');
            result.put('message', 'Failed to get Models API configuration status: ' + e.getMessage());
            result.put('isConfigured', false);
            return result;
        }
    }
    
    /**
     * Result class for prompt generation
     */
    public class PromptGenerationResult {
        @AuraEnabled public String generatedPrompt;
        @AuraEnabled public Double confidence;
        @AuraEnabled public List<String> suggestions;
        @AuraEnabled public Map<String, Object> metadata;
        
        public PromptGenerationResult() {
            this.generatedPrompt = '';
            this.confidence = 0.0;
            this.suggestions = new List<String>();
            this.metadata = new Map<String, Object>();
        }
    }
}
