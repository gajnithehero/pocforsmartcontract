import { SolcInput, SolcOutput } from '../solc-api';
/**
 * Makes a modified version of the solc input to add state variables in each contract for namespaced struct definitions,
 * so that the compiler will generate their types in the storage layout.
 *
 * This makes the following modifications to the input:
 * - Adds a state variable for each namespaced struct definition
 * - For each contract, for all node types that are not needed for storage layout or may call functions and constructors, converts them to dummy enums with random id
 * - Mark contracts as abstract, since state variables are converted to dummy enums which would not generate public getters for inherited interface functions
 * - Converts all using for directives (at file level and in contracts) to dummy enums with random id (do not delete them to avoid orphaning possible NatSpec documentation)
 * - Converts all custom errors and constants (at file level) to dummy enums with the same name (do not delete them since they might be imported by other files)
 * - Replaces functions as follows:
 *   - For regular function and free function, keep declarations since they may be referenced by constants (free functions may also be imported by other files). But simplify compilation as follows:
 *     - Avoid having to initialize return parameters: convert function to virtual if possible, or convert return parameters to bools which can be default initialized.
 *     - Delete modifiers
 *     - Delete function bodies
 *   - Constructors are not needed, since we removed anything that may call constructors. Convert to dummy enums to avoid orphaning possible NatSpec.
 *   - Fallback and receive functions are not needed, since they don't have signatures. Convert to dummy enums to avoid orphaning possible NatSpec.
 *
 * Also sets the outputSelection to only include storageLayout and ast, since the other outputs are not needed.
 *
 * @param input The original solc input.
 * @param output The original solc output.
 * @param _solcVersion The version of the solc compiler that was originally used to compile the input. This argument is no longer used and is kept for backwards compatibility.
 * @returns The modified solc input with storage layout that includes namespaced type information.
 */
export declare function makeNamespacedInput(input: SolcInput, output: SolcOutput, _solcVersion?: string): SolcInput;
/**
 * Attempts to remove all NatSpec comments that do not precede a struct definition from the input source contents.
 * Directly modifies the input source contents, and also returns the modified input.
 *
 * If the solc version is not supported by the parser, the original content is kept.
 *
 * @param solcInput Solc input.
 * @param solcVersion The version of the solc compiler that was originally used to compile the input.
 * @returns The modified solc input with NatSpec comments removed where they do not precede a struct definition.
 */
export declare function trySanitizeNatSpec(solcInput: SolcInput, solcVersion: string): Promise<SolcInput>;
//# sourceMappingURL=make-namespaced.d.ts.map