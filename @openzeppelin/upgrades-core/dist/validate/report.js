"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.UpgradeableContractErrorReport = void 0;
exports.describeError = describeError;
const chalk_1 = __importDefault(require("chalk"));
class UpgradeableContractErrorReport {
    constructor(errors) {
        this.errors = errors;
    }
    get ok() {
        return this.errors.length === 0;
    }
    explain(color = true) {
        return this.errors.map(e => describeError(e, color)).join('\n\n');
    }
}
exports.UpgradeableContractErrorReport = UpgradeableContractErrorReport;
const errorInfo = {
    constructor: {
        msg: e => `Contract \`${e.contract}\` has a constructor`,
        hint: () => 'Define an initializer instead',
        link: 'https://zpl.in/upgrades/error-001',
    },
    delegatecall: {
        msg: () => `Use of delegatecall is not allowed`,
        link: 'https://zpl.in/upgrades/error-002',
    },
    selfdestruct: {
        msg: () => `Use of selfdestruct is not allowed`,
        link: 'https://zpl.in/upgrades/error-003',
    },
    'state-variable-assignment': {
        msg: e => `Variable \`${e.name}\` is assigned an initial value`,
        hint: () => 'Move the assignment to the initializer',
        link: 'https://zpl.in/upgrades/error-004',
    },
    'state-variable-immutable': {
        msg: e => `Variable \`${e.name}\` is immutable and will be initialized on the implementation`,
        hint: () => `If by design, annotate with '@custom:oz-upgrades-unsafe-allow state-variable-immutable'\n` +
            `Otherwise, consider a constant variable or use a mutable variable instead`,
        link: 'https://zpl.in/upgrades/error-005',
    },
    'external-library-linking': {
        msg: e => `Linking external libraries like \`${e.name}\` is not yet supported`,
        hint: () => `Use libraries with internal functions only, or skip this check with the \`unsafeAllowLinkedLibraries\` flag \n` +
            `    if you have manually checked that the libraries are upgrade safe`,
        link: 'https://zpl.in/upgrades/error-006',
    },
    'struct-definition': {
        msg: e => `Structs like \`${e.name}\` are supported in the latest version of the plugin`,
        hint: () => `Update your dependency and run again`,
    },
    'enum-definition': {
        msg: e => `Enums like \`${e.name}\` are supported in the latest version of the plugin`,
        hint: () => `Update your dependency and run again`,
    },
    'missing-public-upgradeto': {
        msg: () => `Implementation is missing a public \`upgradeTo(address)\` or \`upgradeToAndCall(address,bytes)\` function`,
        hint: () => `Inherit UUPSUpgradeable to include one or both of these functions in your contract\n` +
            `    @openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol`,
        link: 'https://zpl.in/upgrades/error-008',
    },
    'internal-function-storage': {
        msg: e => `Variable \`${e.name}\` is an internal function`,
        hint: () => `Use external functions or avoid functions in storage.\n` +
            `     If you must use internal functions, skip this check with the \`unsafeAllow.internal-function-storage\`\n` +
            `     flag and ensure you always reassign internal functions in storage during upgrades`,
        link: 'https://zpl.in/upgrades/error-009',
    },
    'missing-initializer': {
        msg: () => `Missing initializer`,
        hint: () => `Define an initializer function and use it to call the initializers of parent contracts`,
        link: 'https://zpl.in/upgrades/error-001',
    },
    'missing-initializer-call': {
        msg: e => `Missing initializer calls for one or more parent contracts: \`${e.parentContracts.join(', ')}\``,
        hint: () => `Call the parent initializers in your initializer function`,
        link: 'https://zpl.in/upgrades/error-001',
    },
    'duplicate-initializer-call': {
        msg: e => `Duplicate calls found to initializer \`${e.parentInitializer}\` for contract \`${e.parentContract}\``,
        hint: () => `Only call each parent initializer once`,
        link: 'https://zpl.in/upgrades/error-001',
    },
    'incorrect-initializer-order': {
        msg: e => `Incorrect order of parent initializer calls.
- Found initializer calls to parent contracts in the following order: ${e.foundOrder.join(', ')}
- Expected: ${e.expectedLinearization.join(', ')}`,
        hint: () => `Call parent initializers in linearized order`,
    },
};
function describeError(e, color = true) {
    const chalk = new chalk_1.default.Instance({ level: color && chalk_1.default.supportsColor ? chalk_1.default.supportsColor.level : 0 });
    const info = errorInfo[e.kind]; // union type is too complex for TypeScript to represent, so we use `any`
    const log = [chalk.bold(e.src) + ': ' + info.msg(e)];
    const hint = info.hint?.(e);
    if (hint) {
        log.push(hint);
    }
    if (info.link) {
        log.push(chalk.dim(info.link));
    }
    return log.join('\n    ');
}
//# sourceMappingURL=report.js.map