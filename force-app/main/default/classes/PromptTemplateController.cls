/**
 * Apex Controller for Prompt Template Management
 * Handles saving, retrieving, and managing prompt templates
 */
public with sharing class PromptTemplateController {
    


    
    /**
     * Retrieve prompt templates
     * @param category Optional category filter
     * @param limitCount Maximum number of templates to return
     * @return List of template data
     */
    @AuraEnabled
    public static List<Map<String, Object>> getPromptTemplates(String category, Integer limitCount) {
        try {
            // The Connect API classes for prompt templates are not available in this org's API version
            // Return empty list for now until we identify the correct API approach
            
            List<Map<String, Object>> templateList = new List<Map<String, Object>>();
            
            // TODO: Implement actual Prompt Builder integration when the correct API is identified
            // For now, return empty list
            
            // Apply category filter if specified
            if (String.isNotBlank(category)) {
                List<Map<String, Object>> filteredTemplates = new List<Map<String, Object>>();
                for (Map<String, Object> template : templateList) {
                    if (template.get('category') == category) {
                        filteredTemplates.add(template);
                    }
                }
                templateList = filteredTemplates;
            }
            
            // Apply limit
            if (limitCount != null && limitCount > 0 && templateList.size() > limitCount) {
                List<Map<String, Object>> limitedTemplates = new List<Map<String, Object>>();
                for (Integer i = 0; i < limitCount && i < templateList.size(); i++) {
                    limitedTemplates.add(templateList[i]);
                }
                templateList = limitedTemplates;
            }
            
            return templateList;
            
        } catch (Exception e) {
            System.debug('Error retrieving prompt templates: ' + e.getMessage());
            // Fallback to empty list if Connect API fails
            return new List<Map<String, Object>>();
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

