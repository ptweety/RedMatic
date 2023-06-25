const base = require(__dirname + '/addon_files/redmatic/lib/package.json');
const nodes = require(__dirname + '/addon_files/redmatic/var/package.json');
const www = require(__dirname + '/addon_files/redmatic/www/package.json');

const common = require(__dirname + '/package.json');

common.peerDependencies = Object.assign(
    //common.dependencies,
    base.dependencies,
    nodes.dependencies,
    www.dependencies,
);

Object.keys(common.peerDependencies).forEach(name => {
    common.peerDependencies[name] = common.peerDependencies[name];
});

require('fs').writeFileSync(__dirname + '/package.json', JSON.stringify(common, null, '  '));
