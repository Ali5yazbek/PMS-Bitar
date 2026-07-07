const fs = require('fs');
const path = require('path');

function searchDir(dir) {
  let results = [];
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const fullPath = path.join(dir, file);
    if (fs.statSync(fullPath).isDirectory()) {
      results = results.concat(searchDir(fullPath));
    } else if (fullPath.endsWith('.js') || fullPath.endsWith('.jsx')) {
      const content = fs.readFileSync(fullPath, 'utf8');
      const lines = content.split('\n');
      for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (line.match(/\$(?!\{)/)) {
          results.push(fullPath + ':' + (i+1) + ':' + line.trim());
        }
      }
    }
  }
  return results;
}

console.log(searchDir('c:/xampp/htdocs/Bitar/frontend/src').join('\n'));
