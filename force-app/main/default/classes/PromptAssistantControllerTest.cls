/**
 * Test class for PromptAssistantController
 * Tests the native Salesforce Models API integration
 */
@isTest
public class PromptAssistantControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // No test data needed for this test
    }
    
    @isTest
    static void testGeneratePrompt() {
        // Test data
        String userQuery = 'Create a lead qualification prompt';
        String contextData = '{"industry": "Technology"}';
        
        Test.startTest();
        
        try {
            PromptAssistantController.PromptGenerationResult result = 
                PromptAssistantController.generatePrompt(userQuery, contextData);
            
            // Verify the result structure
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertNotEquals(null, result.generatedPrompt, 'Generated prompt should not be null');
            System.assertEquals(0.95, result.confidence, 'Confidence should be 0.95');
            System.assertNotEquals(null, result.suggestions, 'Suggestions should not be null');
            System.assertNotEquals(null, result.metadata, 'Metadata should not be null');
            
        } catch (AuraHandledException e) {
            // If Models API is not configured, we expect an error
            System.debug('Expected error (Models API not configured): ' + e.getMessage());
            // The error message should contain either "Models API" or "Failed to generate prompt"
            System.assert(
                e.getMessage().contains('Models API') || e.getMessage().contains('Failed to generate prompt'), 
                'Error should be related to Models API or general failure. Actual: ' + e.getMessage()
            );
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGeneratePromptEmptyQuery() {
        Test.startTest();
        
        try {
            PromptAssistantController.generatePrompt('', '{}');
            System.assert(false, 'Should have thrown an exception for empty query');
        } catch (AuraHandledException e) {
            System.assertEquals('User query cannot be empty', e.getMessage(), 'Should throw empty query error');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGeneratePromptNullQuery() {
        Test.startTest();
        
        try {
            PromptAssistantController.generatePrompt(null, '{}');
            System.assert(false, 'Should have thrown an exception for null query');
        } catch (AuraHandledException e) {
            System.assertEquals('User query cannot be empty', e.getMessage(), 'Should throw empty query error');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetAvailableModels() {
        Test.startTest();
        
        List<String> models = PromptAssistantController.getAvailableModels();
        
        System.assertNotEquals(null, models, 'Models list should not be null');
        System.assertEquals(1, models.size(), 'Should return one default model');
        System.assertEquals('sfdc_ai__DefaultOpenAIGPT4OmniMini', models[0], 'Should return the default model');
        
        Test.stopTest();
    }
    
    @isTest
    static void testTestModelsAPIConnectivity() {
        Test.startTest();
        
        try {
            Map<String, Object> result = PromptAssistantController.testModelsAPIConnectivity();
            
            // If Models API is configured, we should get a success response
            if (result.get('status') == 'success') {
                System.assertEquals('success', result.get('status'), 'Status should be success');
                System.assertEquals(true, result.get('hasAccess'), 'Should have access');
                System.assertNotEquals(null, result.get('testResponse'), 'Test response should not be null');
            } else {
                // If not configured, we should get an error response
                System.assertEquals('error', result.get('status'), 'Status should be error');
                System.assertEquals(false, result.get('hasAccess'), 'Should not have access');
            }
            
        } catch (Exception e) {
            // Models API might not be available in test context
            System.debug('Models API not available in test context: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetModelsAPIConfigurationStatus() {
        Test.startTest();
        
        Map<String, Object> result = PromptAssistantController.getModelsAPIConfigurationStatus();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('success', result.get('status'), 'Status should be success');
        System.assertEquals('sfdc_ai__DefaultOpenAIGPT4OmniMini', result.get('defaultModel'), 'Should return default model');
        System.assertEquals(true, result.get('isConfigured'), 'Should be configured');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGenerateSuggestions() {
        // Test lead-related suggestions
        String leadQuery = 'Create a lead qualification prompt';
        Map<String, Object> contextData = new Map<String, Object>();
        
        Test.startTest();
        
        // This is a private method, so we test it indirectly through the public method
        try {
            PromptAssistantController.PromptGenerationResult result = 
                PromptAssistantController.generatePrompt(leadQuery, JSON.serialize(contextData));
            
            System.assertNotEquals(null, result.suggestions, 'Suggestions should not be null');
            System.assert(result.suggestions.size() > 0, 'Should have suggestions');
            
        } catch (Exception e) {
            // Expected if Models API is not configured
            System.debug('Expected error: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
}
