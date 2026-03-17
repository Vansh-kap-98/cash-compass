const fs = require('fs');
const path = require('path');

function getAllFiles(dirPath, arrayOfFiles) {
  const files = fs.readdirSync(dirPath);
  arrayOfFiles = arrayOfFiles || [];

  files.forEach(function(file) {
    if (fs.statSync(dirPath + "/" + file).isDirectory()) {
      arrayOfFiles = getAllFiles(dirPath + "/" + file, arrayOfFiles);
    } else {
      arrayOfFiles.push(path.join(dirPath, "/", file));
    }
  });

  return arrayOfFiles;
}

const srcPath = 'c:/Users/greni/Desktop/cash-compass/cc/src';
const filterExts = ['.ts', '.tsx', '.css', '.js'];

const files = getAllFiles(srcPath).filter(f => filterExts.includes(path.extname(f)));

files.forEach(file => {
  let content = fs.readFileSync(file, 'utf8');
  
  if (file.endsWith('.css')) {
    // Remove CSS comments /* */
    content = content.replace(/\/\*[\s\S]*?\*\//g, '');
  } else {
    // Remove JS/TS comments
    // Single line comments
    content = content.replace(/(^|[^\\])\/\/.*$/gm, '$1');
    // Multi line comments
    content = content.replace(/\/\*[\s\S]*?\*\//g, '');
  }

  // Remove empty lines at the end of the file or multiple sequential empty lines
  content = content.replace(/\n\s*\n\s*\n/g, '\n\n');
  
  fs.writeFileSync(file, content, 'utf8');
  console.log(`Cleaned: ${file}`);
});
