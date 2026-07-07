const fs = require('fs');
const parser = require('@babel/parser');
const traverse = require('@babel/traverse').default;

const files = [
    'src/components/AIChatAssistant.jsx',
    'src/components/AIInvestigationReport.jsx',
    'src/components/GeneratorCalendar.jsx',
    'src/components/SupplierPrintLayout.jsx',
    'src/pages/ApartmentElectricity.jsx',
    'src/pages/AuditLogs.jsx',
    'src/pages/BuildingDetails.jsx',
    'src/pages/BuildingSubscriptions.jsx',
    'src/pages/ContractsHub.jsx',
    'src/pages/Depot.jsx',
    'src/pages/Insurance.jsx',
    'src/pages/Login.jsx',
    'src/pages/PendingContracts.jsx',
    'src/pages/ReadingsVerification.jsx',
    'src/pages/Rent.jsx',
    'src/pages/RentInsuranceHub.jsx',
    'src/pages/Reports.jsx',
    'src/pages/ReportsPage.jsx',
    'src/pages/Suppliers.jsx',
    'src/pages/TenantDetails.jsx',
    'src/pages/tenant/TenantContract.jsx',
    'src/pages/tenant/TenantDashboard.jsx',
    'src/pages/tenant/TenantPayments.jsx'
];

let dictionary = JSON.parse(fs.readFileSync('extracted_strings.json', 'utf-8'));

function slugify(text) {
    return text.trim().toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '').substring(0, 30);
}

files.forEach(file => {
    if (!fs.existsSync(file)) return;
    let content = fs.readFileSync(file, 'utf-8');
    
    let fileKey = file.split('/').pop().replace('.jsx', '').toLowerCase();
    
    try {
        const ast = parser.parse(content, {
            sourceType: 'module',
            plugins: ['jsx']
        });
        
        let edits = [];
        
        traverse(ast, {
            JSXText(path) {
                let text = path.node.value;
                let trimmed = text.trim();
                if (trimmed && !/^[\s\d\W]+$/.test(trimmed)) {
                    let key = slugify(trimmed);
                    if (key && dictionary[fileKey][key]) {
                        // We need to keep the surrounding whitespace!
                        let leadingSpace = text.match(/^\s*/)[0];
                        let trailingSpace = text.match(/\s*$/)[0];
                        let replacement = `${leadingSpace}{t('${fileKey}.${key}', { defaultValue: \`${trimmed.replace(/`/g, '\\`')}\` })}${trailingSpace}`;
                        edits.push({
                            start: path.node.start,
                            end: path.node.end,
                            replacement: replacement
                        });
                    }
                }
            },
            StringLiteral(path) {
                if (path.parent.type === 'JSXAttribute') {
                    let attrName = path.parent.name.name;
                    if (['placeholder', 'title', 'label', 'alt'].includes(attrName)) {
                        let text = path.node.value.trim();
                        if (text && !/^[\s\d\W]+$/.test(text)) {
                            let key = slugify(text);
                            if (key && dictionary[fileKey][key]) {
                                // path.node.start/end includes the quotes.
                                let replacement = `{t('${fileKey}.${key}', { defaultValue: \`${text.replace(/`/g, '\\`')}\` })}`;
                                edits.push({
                                    start: path.node.start,
                                    end: path.node.end,
                                    replacement: replacement
                                });
                            }
                        }
                    }
                }
            }
        });
        
        // Sort edits from back to front
        edits.sort((a, b) => b.start - a.start);
        
        // Apply edits
        for (let edit of edits) {
            content = content.slice(0, edit.start) + edit.replacement + content.slice(edit.end);
        }
        
        // Inject import and hook
        if (!content.includes('useTranslation')) {
            content = "import { useTranslation } from 'react-i18next';\n" + content;
            
            // Try to find the component definition to inject the hook
            // Simple regex to find the first component body
            content = content.replace(/(const\s+\w+\s*=\s*\([^)]*\)\s*=>\s*\{)/, "$1\n  const { t } = useTranslation();\n");
            // Also handle standard function components
            content = content.replace(/(function\s+\w+\s*\([^)]*\)\s*\{)/, "$1\n  const { t } = useTranslation();\n");
        }
        
        fs.writeFileSync(file, content, 'utf-8');
        console.log(`Updated ${file} with ${edits.length} translations.`);
        
    } catch (e) {
        console.error("Error modifying", file, e.message);
    }
});

console.log("Injection complete!");
