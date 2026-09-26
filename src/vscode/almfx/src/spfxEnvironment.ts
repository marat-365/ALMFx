import * as fs from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';
import { spawn } from 'child_process';

/**
 * Domain facts (what these functions do, prod/production defaulting, etc.)
 * are documented once in docs/reference/spfx-alm/ and in the PowerShell
 * functions' own comment-based help. This file only wires the UI to them.
 */

type SPFxEnvironmentFunction = 'New-SPFxEnvironment' | 'Set-SPFxEnvironment';

interface RunResult {
    readonly stdout: string;
    readonly stderr: string;
    readonly exitCode: number | null;
}

const ENVIRONMENT_NAME_PATTERN = /^[A-Za-z0-9][A-Za-z0-9_-]*$/;

function isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null;
}

export async function runNewSPFxEnvironment(output: vscode.OutputChannel): Promise<void> {
    const solutionPath = await pickSolutionPath();
    if (!solutionPath) {
        return;
    }

    const environment = await promptForEnvironmentName();
    if (!environment) {
        return;
    }

    const createUniqueNames = await promptForCreateUniqueNames(environment);
    if (createUniqueNames === undefined) {
        return;
    }

    await runAndReport(
        output,
        'New-SPFxEnvironment',
        solutionPath,
        environment,
        createUniqueNames,
        (parsed) => {
            const files = isRecord(parsed) ? parsed['Files'] : undefined;
            const fileCount = Array.isArray(files) ? files.length : 0;
            return `Built .${environment}/ with ${fileCount} file(s).`;
        }
    );
}

export async function runSetSPFxEnvironment(output: vscode.OutputChannel): Promise<void> {
    const solutionPath = await pickSolutionPath();
    if (!solutionPath) {
        return;
    }

    const environment = await promptForExistingEnvironmentName(solutionPath);
    if (!environment) {
        return;
    }

    const confirmed = await vscode.window.showWarningMessage(
        `Deploy .${environment}/ into ${solutionPath}? This overwrites matching files at their normal locations.`,
        { modal: true },
        'Deploy'
    );
    if (confirmed !== 'Deploy') {
        return;
    }

    await runAndReport(
        output,
        'Set-SPFxEnvironment',
        solutionPath,
        environment,
        undefined,
        (parsed) => {
            const fileCount = Array.isArray(parsed) ? parsed.length : 0;
            return `Deployed ${fileCount} file(s) from .${environment}/.`;
        }
    );
}

async function pickSolutionPath(): Promise<string | undefined> {
    const workspaceFolders = vscode.workspace.workspaceFolders;
    if (workspaceFolders && workspaceFolders.length === 1) {
        return workspaceFolders[0].uri.fsPath;
    }

    const defaultUri = workspaceFolders?.[0]?.uri;
    const picked = await vscode.window.showOpenDialog({
        canSelectFiles: false,
        canSelectFolders: true,
        canSelectMany: false,
        openLabel: 'Select SPFx solution folder',
        ...(defaultUri ? { defaultUri } : {})
    });
    return picked?.[0]?.fsPath;
}

async function promptForEnvironmentName(): Promise<string | undefined> {
    return vscode.window.showInputBox({
        title: 'Environment name',
        prompt: 'e.g. dev, test, prod',
        placeHolder: 'dev',
        validateInput: (value) => {
            if (!ENVIRONMENT_NAME_PATTERN.test(value)) {
                return 'Must start with a letter or digit, then letters, digits, "_" or "-" only.';
            }
            return undefined;
        }
    });
}

/**
 * For Set-SPFxEnvironment: offers a QuickPick of already-built .<environment>/
 * folders under the solution (the ones New-SPFxEnvironment actually produced),
 * falling back to free text entry if none exist yet or the user wants a
 * different name.
 */
async function promptForExistingEnvironmentName(solutionPath: string): Promise<string | undefined> {
    const built = listBuiltEnvironments(solutionPath);
    if (built.length === 0) {
        return promptForEnvironmentName();
    }

    const typeManually = '$(edit) Type a different name...';
    const choice = await vscode.window.showQuickPick([...built, typeManually], {
        title: 'Which built environment should be deployed?',
        placeHolder: 'dev'
    });

    if (choice === undefined) {
        return undefined;
    }
    return choice === typeManually ? promptForEnvironmentName() : choice;
}

function listBuiltEnvironments(solutionPath: string): string[] {
    let entries: fs.Dirent[];
    try {
        entries = fs.readdirSync(solutionPath, { withFileTypes: true });
    } catch {
        return [];
    }

    return entries
        .filter((entry) => entry.isDirectory())
        .map((entry) => entry.name)
        .filter((name) => name.startsWith('.') && ENVIRONMENT_NAME_PATTERN.test(name.slice(1)))
        .map((name) => name.slice(1))
        .sort();
}

/**
 * Mirrors New-SPFxEnvironment's own default (true unless prod/production,
 * case-insensitive) as the pre-selected QuickPick item, while still letting
 * the user override it either way - same as passing -CreateUniqueNames
 * explicitly on the command line.
 */
async function promptForCreateUniqueNames(environment: string): Promise<boolean | undefined> {
    const recommendedDefault = !['prod', 'production'].includes(environment.toLowerCase());

    const yes = 'Yes - fresh GUIDs and "_<environment>"-suffixed names';
    const no = 'No - keep the real, original identity unchanged';
    const recommended = '(recommended for this name)';
    const items: vscode.QuickPickItem[] = [
        { label: yes, ...(recommendedDefault ? { description: recommended } : {}) },
        { label: no, ...(!recommendedDefault ? { description: recommended } : {}) }
    ];

    const choice = await vscode.window.showQuickPick(items, {
        title: `-CreateUniqueNames for "${environment}"?`,
        placeHolder: recommendedDefault ? yes : no
    });

    if (choice === undefined) {
        return undefined;
    }
    return choice.label === yes;
}

async function runAndReport(
    output: vscode.OutputChannel,
    functionName: SPFxEnvironmentFunction,
    solutionPath: string,
    environment: string,
    createUniqueNames: boolean | undefined,
    describeSuccess: (parsed: unknown) => string
): Promise<void> {
    output.show(true);
    output.appendLine(`> ${functionName} -Path "${solutionPath}" -Environment "${environment}"`);

    await vscode.window.withProgress(
        { location: vscode.ProgressLocation.Notification, title: `ALMFx: ${functionName}`, cancellable: true },
        async (_progress, token) => {
            let result: RunResult;
            try {
                result = await invokeShim(functionName, solutionPath, environment, createUniqueNames, token);
            } catch (error) {
                const message = error instanceof Error ? error.message : String(error);
                output.appendLine(`error: ${message}`);
                await vscode.window.showErrorMessage(`ALMFx: ${functionName} failed to start - ${message}`);
                return;
            }

            if (result.stderr.trim().length > 0) {
                output.appendLine(result.stderr.trimEnd());
            }

            if (result.exitCode !== 0) {
                await vscode.window.showErrorMessage(
                    `ALMFx: ${functionName} failed. See the ALMFx output channel for details.`
                );
                return;
            }

            output.appendLine(result.stdout.trimEnd());

            try {
                const parsed: unknown = JSON.parse(result.stdout || 'null');
                await vscode.window.showInformationMessage(`ALMFx: ${describeSuccess(parsed)}`);
            } catch {
                await vscode.window.showInformationMessage(`ALMFx: ${functionName} completed.`);
            }
        }
    );
}

async function invokeShim(
    functionName: SPFxEnvironmentFunction,
    solutionPath: string,
    environment: string,
    createUniqueNames: boolean | undefined,
    token: vscode.CancellationToken
): Promise<RunResult> {
    const scriptPath = path.join(__dirname, '..', 'resources', 'Invoke-SPFxEnvironmentCommand.ps1');

    const args = ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', scriptPath];

    const modulePath = resolveModulePath();
    if (modulePath) {
        args.push('-ModulePath', modulePath);
    }

    args.push('-FunctionName', functionName, '-Path', solutionPath, '-Environment', environment);

    if (createUniqueNames !== undefined) {
        args.push('-CreateUniqueNamesSpecified', '-CreateUniqueNames', createUniqueNames ? 'True' : 'False');
    }

    for (const executable of resolvePowerShellExecutables()) {
        try {
            return await spawnAndCollect(executable, args, token);
        } catch (error) {
            const isMissingExecutable = isErrnoException(error) && error.code === 'ENOENT';
            if (!isMissingExecutable) {
                throw error;
            }
            // Try the next candidate (see resolvePowerShellExecutables); if
            // this was the last one, the loop falls through and the final
            // ENOENT below is thrown to the caller.
        }
    }

    throw new Error(`Could not find a PowerShell executable (tried: ${resolvePowerShellExecutables().join(', ')}).`);
}

function spawnAndCollect(
    executable: string,
    args: string[],
    token: vscode.CancellationToken
): Promise<RunResult> {
    return new Promise((resolve, reject) => {
        const child = spawn(executable, args, { windowsHide: true });

        let stdout = '';
        let stderr = '';
        child.stdout.on('data', (chunk: Buffer) => (stdout += chunk.toString()));
        child.stderr.on('data', (chunk: Buffer) => (stderr += chunk.toString()));

        const onCancel = token.onCancellationRequested(() => child.kill());

        child.on('error', (error) => {
            onCancel.dispose();
            reject(error);
        });

        child.on('close', (exitCode) => {
            onCancel.dispose();
            resolve({ stdout, stderr, exitCode });
        });
    });
}

function isErrnoException(error: unknown): error is NodeJS.ErrnoException {
    return error instanceof Error && 'code' in error;
}

/**
 * PowerShell 7+ (`pwsh`) is tried first; Windows PowerShell 5.1
 * (`powershell.exe`) is the fallback if `pwsh` isn't on `PATH`, since
 * New-SPFxEnvironment/Set-SPFxEnvironment are pure filesystem/text
 * operations that run on both - see AGENTS.md's PowerShell conventions on
 * why 5.1 support is deliberate, not legacy baggage. An explicit
 * `almfx.powershellPath` setting skips this search entirely.
 */
function resolvePowerShellExecutables(): string[] {
    const configured = vscode.workspace.getConfiguration('almfx').get<string>('powershellPath');
    if (configured) {
        return [configured];
    }
    return process.platform === 'win32' ? ['pwsh.exe', 'powershell.exe'] : ['pwsh'];
}

/**
 * Explicit setting first; otherwise the module manifest that ships alongside
 * this monorepo's own source (works when developing/testing the extension
 * from a checkout of this repository). Once ALMFx is published to the
 * PowerShell Gallery and this extension to the Marketplace, neither path
 * will exist for an end user with an independently-installed module, so
 * falling through to a bare `Import-Module ALMFx` (relying on
 * $env:PSModulePath) is the last resort - see resources/
 * Invoke-SPFxEnvironmentCommand.ps1.
 */
function resolveModulePath(): string | undefined {
    const configured = vscode.workspace.getConfiguration('almfx').get<string>('modulePath');
    if (configured) {
        return configured;
    }

    const devManifest = path.join(__dirname, '..', '..', '..', 'powershell', 'ALMFx', 'ALMFx.psd1');
    return fs.existsSync(devManifest) ? devManifest : undefined;
}
