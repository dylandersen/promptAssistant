/**
 * Apex Controller for Prompt Template Management
 * Handles saving, retrieving, and managing prompt templates
 */
public with sharing class PromptTemplateController {
    
    /**
     * Save a prompt template
     * @param templateData JSON string containing template data
     * @return String ID of the saved template
     */
    @AuraEnabled
    public static String savePromptTemplate(String templateData) {
        try {
            // Parse template data
            Map<String, Object> templateMap = (Map<String, Object>) JSON.deserializeUntyped(templateData);
            
            // Validate required fields
            if (!templateMap.containsKey('name') || String.isBlank((String) templateMap.get('name'))) {
                throw new AuraHandledException('Template name is required');
            }
            
            if (!templateMap.containsKey('content') || String.isBlank((String) templateMap.get('content'))) {
                throw new AuraHandledException('Template content is required');
            }
            
            // Create custom object record (if using custom object)
            // For demo purposes, we'll just return a success message
            // In production, this would save to a custom object or external system
            
            String templateId = 'TEMPLATE_' + String.valueOf(Datetime.now().getTime());
            
            // Log template creation for audit purposes
            System.debug('Prompt Template Created: ' + templateMap.get('name') + ' (ID: ' + templateId + ')');
            
            return templateId;
            
        } catch (Exception e) {
            System.debug('Error saving prompt template: ' + e.getMessage());
            throw new AuraHandledException('Failed to save template: ' + e.getMessage());
        }
    }
    
    /**
     * Retrieve prompt templates
     * @param category Optional category filter
     * @param limitCount Maximum number of templates to return
     * @return List of template data
     */
    @AuraEnabled
    public static List<Map<String, Object>> getPromptTemplates(String category, Integer limitCount) {
        try {
            // Mock template data for demonstration
            // In production, this would query from a custom object or external system
            
            List<Map<String, Object>> templates = new List<Map<String, Object>>();
            
            // Sample templates
            Map<String, Object> template1 = new Map<String, Object>{
                'id' => 'TEMPLATE_001',
                'name' => 'Lead Qualification Template',
                'description' => 'Template for qualifying leads based on BANT criteria',
                'content' => 'Analyze the lead {{leadName}} from {{company}} in the {{industry}} industry...',
                'category' => 'lead-qualification',
                'variables' => new List<String>{'leadName', 'company', 'industry'},
                'createdDate' => Datetime.now().addDays(-5).format('yyyy-MM-dd HH:mm:ss'),
                'isPublic' => true
            };
            
            Map<String, Object> template2 = new Map<String, Object>{
                'id' => 'TEMPLATE_002',
                'name' => 'Customer Service Response',
                'description' => 'Standard customer service response template',
                'content' => 'Thank you for contacting us regarding your {{issueType}}...',
                'category' => 'customer-service',
                'variables' => new List<String>{'issueType', 'customerName'},
                'createdDate' => Datetime.now().addDays(-3).format('yyyy-MM-dd HH:mm:ss'),
                'isPublic' => true
            };
            
            Map<String, Object> template3 = new Map<String, Object>{
                'id' => 'TEMPLATE_003',
                'name' => 'Sales Follow-up Template',
                'description' => 'Professional follow-up message for sales prospects',
                'content' => 'Hi {{contactName}}, I hope this message finds you well...',
                'category' => 'sales',
                'variables' => new List<String>{'contactName', 'companyName', 'meetingDate'},
                'createdDate' => Datetime.now().addDays(-1).format('yyyy-MM-dd HH:mm:ss'),
                'isPublic' => false
            };
            
            templates.add(template1);
            templates.add(template2);
            templates.add(template3);
            
            // Apply category filter if specified
            if (String.isNotBlank(category)) {
                List<Map<String, Object>> filteredTemplates = new List<Map<String, Object>>();
                for (Map<String, Object> template : templates) {
                    if (template.get('category') == category) {
                        filteredTemplates.add(template);
                    }
                }
                templates = filteredTemplates;
            }
            
            // Apply limit
            if (limitCount != null && limitCount > 0 && templates.size() > limitCount) {
                List<Map<String, Object>> limitedTemplates = new List<Map<String, Object>>();
                for (Integer i = 0; i < limitCount && i < templates.size(); i++) {
                    limitedTemplates.add(templates[i]);
                }
                templates = limitedTemplates;
            }
            
            return templates;
            
        } catch (Exception e) {
            System.debug('Error retrieving prompt templates: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve templates: ' + e.getMessage());
        }
    }
    
    /**
     * Export template to Prompt Builder format
     * @param templateId The ID of the template to export
     * @return Map containing Prompt Builder compatible data
     */
    @AuraEnabled
    public static Map<String, Object> exportToPromptBuilder(String templateId) {
        try {
            // Mock export data for demonstration
            // In production, this would format the template for Prompt Builder API
            
            Map<String, Object> exportData = new Map<String, Object>{
                'templateId' => templateId,
                'promptBuilderFormat' => 'v1.0',
                'template' => new Map<String, Object>{
                    'name' => 'Exported Template',
                    'description' => 'Template exported from Context7 Prompt Assistant',
                    'content' => 'This is the prompt content that would be imported into Prompt Builder.',
                    'variables' => new List<String>{'var1', 'var2', 'var3'},
                    'metadata' => new Map<String, Object>{
                        'source' => 'Context7 Prompt Assistant',
                        'exportDate' => Datetime.now().format('yyyy-MM-dd HH:mm:ss'),
                        'version' => '1.0'
                    }
                }
            };
            
            return exportData;
            
        } catch (Exception e) {
            System.debug('Error exporting template: ' + e.getMessage());
            throw new AuraHandledException('Failed to export template: ' + e.getMessage());
        }
    }
    
    /**
     * Validate template syntax and content
     * @param templateContent The template content to validate
     * @return Map containing validation results
     */
    @AuraEnabled
    public static Map<String, Object> validateTemplate(String templateContent) {
        try {
            Map<String, Object> validationResult = new Map<String, Object>();
            List<String> errors = new List<String>();
            List<String> warnings = new List<String>();
            
            // Basic validation checks
            if (String.isBlank(templateContent)) {
                errors.add('Template content cannot be empty');
            } else {
                // Check for variable syntax
                Pattern variablePattern = Pattern.compile('\\{\\{([^}]+)\\}\\}');
                Matcher matcher = variablePattern.matcher(templateContent);
                Set<String> variables = new Set<String>();
                
                while (matcher.find()) {
                    variables.add(matcher.group(1));
                }
                
                if (variables.size() > 10) {
                    warnings.add('Template contains many variables (' + variables.size() + '). Consider simplifying.');
                }
                
                if (templateContent.length() > 2000) {
                    warnings.add('Template is quite long (' + templateContent.length() + ' characters). Consider breaking into smaller chunks.');
                }
                
                if (templateContent.length() < 50) {
                    warnings.add('Template is very short. Consider adding more context and instructions.');
                }
                
                // Check for common issues
                if (templateContent.toLowerCase().contains('send this') || templateContent.toLowerCase().contains('send that')) {
                    warnings.add('Consider using more specific language instead of "send this/that".');
                }
                
                if (!templateContent.contains('{{') && !templateContent.contains('}}')) {
                    warnings.add('No variables detected. Consider adding dynamic placeholders for personalization.');
                }
            }
            
            validationResult.put('isValid', errors.isEmpty());
            validationResult.put('errors', errors);
            validationResult.put('warnings', warnings);
            validationResult.put('score', calculateValidationScore(errors, warnings));
            
            return validationResult;
            
        } catch (Exception e) {
            System.debug('Error validating template: ' + e.getMessage());
            throw new AuraHandledException('Failed to validate template: ' + e.getMessage());
        }
    }
    
    /**
     * Calculate validation score (0-100)
     */
    private static Integer calculateValidationScore(List<String> errors, List<String> warnings) {
        Integer score = 100;
        
        // Deduct points for errors
        score -= (errors.size() * 20);
        
        // Deduct points for warnings
        score -= (warnings.size() * 5);
        
        return Math.max(0, score);
    }
    
    /**
     * Get template categories for dropdown
     * @return List of category options
     */
    @AuraEnabled
    public static List<Map<String, String>> getTemplateCategories() {
        List<Map<String, String>> categories = new List<Map<String, String>>();
        
        categories.add(new Map<String, String>{'label' => 'Sales', 'value' => 'sales'});
        categories.add(new Map<String, String>{'label' => 'Customer Service', 'value' => 'customer-service'});
        categories.add(new Map<String, String>{'label' => 'Marketing', 'value' => 'marketing'});
        categories.add(new Map<String, String>{'label' => 'Data Analysis', 'value' => 'data-analysis'});
        categories.add(new Map<String, String>{'label' => 'Lead Qualification', 'value' => 'lead-qualification'});
        categories.add(new Map<String, String>{'label' => 'Follow-up', 'value' => 'follow-up'});
        categories.add(new Map<String, String>{'label' => 'Onboarding', 'value' => 'onboarding'});
        categories.add(new Map<String, String>{'label' => 'Training', 'value' => 'training'});
        categories.add(new Map<String, String>{'label' => 'General', 'value' => 'general'});
        
        return categories;
    }
}
