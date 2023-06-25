const fs = require('fs');
const request = require('sync-request');

console.log('\nAssemble Readme files');

let out = fs.readFileSync(__dirname + '/docs/README.header.md').toString();

let res = request('GET', 'https://raw.githubusercontent.com/wiki/ptweety/RedMatic/Intro.md');
if (res && res.statusCode === 200) {
    console.log('  fetched wiki/Intro');
    out += res.body.toString();
}

out += '\n## Dokumentation\n\n';

res = request('GET', 'https://raw.githubusercontent.com/wiki/ptweety/RedMatic/Home.md');
if (res && res.statusCode === 200) {
    console.log('  fetched wiki/Home');
    let toc = res.body.toString();
    toc = toc.replace(/^.*\(Intro\)\n/, '');
    toc = toc.replace(/]\((?!http)/g, '](https://github.com/ptweety/RedMatic/wiki/');
    out += toc;
}

out += '\n\n\n' + fs.readFileSync(__dirname + '/docs/README.footer.md').toString();

fs.writeFileSync('README.md', out);



out = fs.readFileSync(__dirname + '/docs/README.header.en.md').toString();

res = request('GET', 'https://raw.githubusercontent.com/wiki/ptweety/RedMatic/en:Intro.md');
if (res && res.statusCode === 200) {
    console.log('  fetched wiki/en:Intro');
    out += res.body.toString();
}

out += '\n## Documentation\n\n';

res = request('GET', 'https://raw.githubusercontent.com/wiki/ptweety/RedMatic/en:Home.md');
if (res && res.statusCode === 200) {
    console.log('  fetched wiki/en:Home');
    let toc = res.body.toString();
    toc = toc.replace(/^.*\(Intro\)\n/, '');
    toc = toc.replace(/]\((?!http)/g, '](https://github.com/ptweety/RedMatic/wiki/');
    out += toc;
}

out += '\n\n\n' + fs.readFileSync(__dirname + '/docs/README.footer.en.md').toString();

fs.writeFileSync('README.en.md', out);

console.log('  done.');
