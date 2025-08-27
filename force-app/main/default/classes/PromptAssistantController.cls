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
        
        // System instruction for Salesforce Prompt Builder context
        enhancedPrompt += 'You are a Salesforce expert specializing in prompt engineering for Salesforce Prompt Builder. ';
        enhancedPrompt += 'Your task is to create effective prompt templates that can be used in Salesforce workflows, flows, and automation. ';
        enhancedPrompt += 'The prompts should follow best practices for Salesforce Prompt Builder including:\n\n';
        enhancedPrompt += '1. Clear, specific instructions\n';
        enhancedPrompt += '2. Proper variable formatting with {{variableName}}\n';
        enhancedPrompt += '3. Salesforce-specific terminology and field references\n';
        enhancedPrompt += '4. Appropriate tone and length for the use case\n';
        enhancedPrompt += '5. Security and data privacy considerations\n\n';
        
        // Add context information if available
        if (contextData != null && !contextData.isEmpty()) {
            enhancedPrompt += 'Context Information:\n';
            for (String key : contextData.keySet()) {
                enhancedPrompt += '- ' + key + ': ' + contextData.get(key) + '\n';
            }
            enhancedPrompt += '\n';
        }
        
        // Add the user's specific request
        enhancedPrompt += 'User Request: ' + userQuery + '\n\n';
        enhancedPrompt += 'Please create a Salesforce Prompt Builder template that addresses this request. ';
        enhancedPrompt += 'Include any relevant variables that should be replaced with Salesforce field data. ';
        enhancedPrompt += 'Make the prompt professional, clear, and actionable. ';
        enhancedPrompt += 'Format your response as a ready-to-use prompt template.';
        
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
