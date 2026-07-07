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

let dictionary = {};

function slugify(text) {
    return text.trim().toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '').substring(0, 30);
}

files.forEach(file => {
    if (!fs.existsSync(file)) return;
    const content = fs.readFileSync(file, 'utf-8');
    
    try {
        const ast = parser.parse(content, {
            sourceType: 'module',
            plugins: ['jsx']
        });
        
        let fileKey = file.split('/').pop().replace('.jsx', '').toLowerCase();
        dictionary[fileKey] = {};
        
        traverse(ast, {
            JSXText(path) {
                let text = path.node.value.trim();
                if (text && !/^[\s\d\W]+$/.test(text)) {
                    let key = slugify(text);
                    if (key) {
                        dictionary[fileKey][key] = text;
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
                            if (key) {
                                dictionary[fileKey][key] = text;
                            }
                        }
                    }
                }
            }
        });
    } catch (e) {
        console.error("Error parsing", file, e.message);
    }
});

fs.writeFileSync('extracted_strings.json', JSON.stringify(dictionary, null, 2));
console.log("Extraction complete!");
