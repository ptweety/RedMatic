const fs = require('fs');
const cp = require('child_process');
const crypto = require('crypto');
const pkgLib = require(__dirname + '/addon_files/redmatic/lib/package.json');
const redmaticVersion = require(__dirname + '/package.json').version;

let tarch = process.argv[2] || 'armv7l';
let arch = '';

if (tarch !== 'armv7l') {
    arch = '-' + tarch;
}

const blacklist = [
    'node-red',
    'npm',
    'ain2'
];

const extraFiles = {
    'redmatic-homekit': [
        'bin/ffmpeg'
    ],
    'node-red-contrib-johnny-five': [
        'bin/pig2vcd',
        'bin/pigpiod',
        'bin/pigs',
        'lib/libpigpio.so',
        'lib/libpigpiod_if.so',
        'lib/libpigpiod_if2.so',
    ]
};

if (arch === 'armv7l') {
    extraFiles['node-red-contrib-johnny-five'].push('lib/libpigpio.so.1');
    extraFiles['node-red-contrib-johnny-five'].push('lib/libpigpiod_if.so.1');
    extraFiles['node-red-contrib-johnny-five'].push('lib/libpigpiod_if2.so.1');
}

const remove = [];
const repo = {};

// TODO handle scoped packages

Object.keys(pkgLib.dependencies).forEach(name => {
    if (blacklist.includes(name)) {
        return;
    }

    remove.push(__dirname + '/addon_tmp/redmatic/lib/node_modules/' + name);

    if ((tarch === 'i686' || tarch === 'x86_64') && name === 'node-red-contrib-johnny-five') {
        return;
    }

    let pkgJson;
    try {
        pkgJson = require(__dirname + '/addon_tmp/redmatic/lib/node_modules/' + name + '/package.json');
    } catch (err) {
        console.error(err.message);
        return;
    }
    const {version, description, keywords, homepage, repository} = pkgJson;

    const filename = 'redmatic' + arch + '-pkg-' + name + '-' + version + '.tar.gz';

    let cmd = 'tar -C ' + __dirname + '/addon_tmp/redmatic/ -czf ' + __dirname + '/dist/' + filename + ' lib/node_modules/' + name;
    if (extraFiles[name]) {
        extraFiles[name].forEach(file => {
            cmd += ' ' + file;
            remove.push(__dirname + '/addon_tmp/redmatic/' + file);
        });
    }
    console.log(`  ${filename}`);
    try {
        cp.execSync(cmd);
        repo[name] = {
            integrity: checksum(fs.readFileSync(__dirname + '/dist/' + filename)),
            resolved: 'https://github.com/rdmtc/RedMatic/releases/download/v' + redmaticVersion + '/' + filename,
            version,
            description,
            keywords,
            homepage,
            repository
        };
    } catch (error) {
        console.error(error.message);
    }
});

fs.writeFileSync(__dirname + '/addon_tmp/redmatic/lib/pkg-repo.json', JSON.stringify(repo, null, '  '));

remove.forEach(path => {
    console.log('remove', path);
    if (fs.existsSync(path)) {
        if (fs.statSync(path).isDirectory()) {
            try {
                cp.execSync('rm -r ' + path);
            } catch (error) {
                console.error(error.message);
            }
        } else {
            fs.unlinkSync(path);
        }
    } else {
        console.log(path, 'does not exist');
    }
});

function checksum(input) {
    const hash = crypto.createHash('sha512').update(input, 'utf8');
    return 'sha512-' + hash.digest('base64');
}
