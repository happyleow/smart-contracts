const branch = require('git-branch');
const assert = require('assert');
const { getDeploymentBlockchain, saveDeploymentBlockchain } = require('../utils');

const branchToEnv = {
    "develop" : "test",
    "staging" : "staging",
    "master" : "prod",
};

const networkToBlockchain = {
    'ropsten' : 'eth',
    'ropstenStaging' : 'eth',
    'binancetest' : 'bsc',
    'binancetestStaging' : 'bsc'
};

/**
 * Function to generate tenderly slug
 * @returns {string}
 */
const generateTenderlySlug = () => {
    let gitBranch = branch.sync();

    let network;
    if(process.argv.length > 2) {
        network = process.argv[4];
        saveDeploymentBlockchain(network);
    } else {
        network = getDeploymentBlockchain()['network'];
    }
    // console.log(`chainport-${networkToBlockchain[network]}-${branchToEnv[gitBranch]}`)
    return `chainport-${networkToBlockchain[network]}-${branchToEnv[gitBranch]}`;
};


const checksumNetworkAndBranch = (network) => {
    const gitBranch = branch.sync();
    if(network === 'ropsten' || network === 'binancetest') {
        assert.strictEqual(gitBranch ,'develop','Wrong branch');
    }
    else if(network === 'ropstenStaging' || network === 'binanceStaging') {
        assert.strictEqual(gitBranch ,'staging','Wrong branch');
    }
    else if(network === 'mainnet' || network === 'binanceMainnet') {
        assert.strictEqual(gitBranch ,'master','Wrong branch');
    } else {
        new Error('Wrong network configuration')
    }
};


const toCamel = (s) => {
    return s.replace(/([-_][a-z])/ig, ($1) => {
        return $1.toUpperCase()
            .replace('-', '')
            .replace('_', '');
    });
};

module.exports = {
    generateTenderlySlug,
    checksumNetworkAndBranch,
    toCamel
}