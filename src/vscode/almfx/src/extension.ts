import * as vscode from 'vscode';

/**
 * Diagnostics channel. Shipped code never writes to `console`, so this is the
 * only place extension output goes.
 */
let output: vscode.OutputChannel;

export function activate(context: vscode.ExtensionContext): void {
    output = vscode.window.createOutputChannel('ALMFx');
    context.subscriptions.push(output);

    context.subscriptions.push(
        vscode.commands.registerCommand('almfx.showVersion', () => showVersion(context))
    );

    output.appendLine('ALMFx activated.');
}

export function deactivate(): void {
    // Everything is registered on context.subscriptions and disposed for us.
}

/**
 * Placeholder command. Exists so the activation, registration, disposal and
 * output-channel wiring is real and testable before any ALM logic lands.
 */
async function showVersion(context: vscode.ExtensionContext): Promise<void> {
    const version = context.extension.packageJSON.version as string;
    const tenantUrl = vscode.workspace.getConfiguration('almfx').get<string>('tenantUrl');

    output.appendLine(`Version ${version}; tenantUrl=${tenantUrl || '(not set)'}`);

    await vscode.window.showInformationMessage(`ALMFx ${version}`);
}
