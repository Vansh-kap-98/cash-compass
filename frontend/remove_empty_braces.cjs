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
const filterExts = ['.tsx'];

const files = getAllFiles(srcPath).filter(f => filterExts.includes(path.extname(f)));

files.forEach(file => {
  let content = fs.readFileSync(file, 'utf8');
  
  // Remove empty {} and { } and {\n} etc. that often come from removed comments
  content = content.replace(/\{\s*\}/g, '');
  
  // Clean up excessive newlines again
  content = content.replace(/\n\s*\n\s*\n/g, '\n\n');
  
  fs.writeFileSync(file, content, 'utf8');
});
