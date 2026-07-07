const fs = require('fs');
const path = require('path');

function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(file => {
        const filePath = path.join(dir, file);
        const stat = fs.statSync(filePath);
        if (stat && stat.isDirectory()) { 
            results = results.concat(walk(filePath));
        } else if (file.endsWith('.jsx') || file.endsWith('.js')) {
            results.push(filePath);
        }
    });
    return results;
}

const files = walk('c:/xampp/htdocs/Bitar/frontend/src');

files.forEach(file => {
    let content = fs.readFileSync(file, 'utf8');
    let newContent = content;
    
    // Replace >$ with >CFA 
    newContent = newContent.replace(/>\$/g, '>CFA ');
    // Replace ($) with (CFA)
    newContent = newContent.replace(/\(\$\)/g, '(CFA)');
    // Replace `${` (Wait, NO! $${...} only)
    newContent = newContent.replace(/\$\$\{/g, 'CFA ${');
    // Replace '$' with 'CFA'
    newContent = newContent.replace(/'\$'/g, "'CFA'");
    // Replace "$ " with "CFA "
    newContent = newContent.replace(/"\$ "/g, '"CFA "');
    
    // Some places use: <span className="text-slate-400">$</span>
    // which is caught by >\$
    
    // Let's also look for `$` preceding `{` that is not inside a template string. Wait, >\$\{ replaces `>${` which we DON'T want.
    // >\$ replaces `>$` so `>${` becomes `>CFA {` which is CORRECT in JSX! 
    // Yes! In JSX `<p>${total}</p>` becomes `<p>CFA {total}</p>`
    
    if (content !== newContent) {
        fs.writeFileSync(file, newContent, 'utf8');
        console.log(`Updated ${file}`);
    }
});
