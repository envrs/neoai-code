import * as vscode from 'vscode';
import * as https from 'https';
import * as http from 'http';
import * as url from 'url';

export interface ProxySettings {
	enabled: boolean;
	host?: string;
	port?: number;
	username?: string;
	password?: string;
	bypass?: string[];
}

export class ProxyProvider implements vscode.Disposable {
	private disposables: vscode.Disposable[] = [];
	private proxySettings: ProxySettings;

	constructor() {
		this.proxySettings = this.loadProxySettings();
		this.setupConfigurationListener();
	}

	private loadProxySettings(): ProxySettings {
		const config = vscode.workspace.getConfiguration('neoai');
		const useProxy = config.get<boolean>('useProxySupport', true);
		
		if (!useProxy) {
			return { enabled: false };
		}

		// Try to get proxy settings from environment variables first
		const httpProxy = process.env.HTTP_PROXY || process.env.http_proxy;
		const httpsProxy = process.env.HTTPS_PROXY || process.env.https_proxy;
		const noProxy = process.env.NO_PROXY || process.env.no_proxy;

		if (httpProxy || httpsProxy) {
			const proxyUrl = httpsProxy || httpProxy;
			const parsed = url.parse(proxyUrl);
			
			return {
				enabled: true,
				host: parsed.hostname,
				port: parsed.port ? parseInt(parsed.port) : (parsed.protocol === 'https:' ? 443 : 80),
				username: parsed.auth ? parsed.auth.split(':')[0] : undefined,
				password: parsed.auth ? parsed.auth.split(':')[1] : undefined,
				bypass: noProxy ? noProxy.split(',').map(s => s.trim()) : undefined
			};
		}

		// Fall back to VSCode proxy settings
		const vscodeHttpProxy = vscode.workspace.getConfiguration('http').get<string>('proxy');
		if (vscodeHttpProxy) {
			const parsed = url.parse(vscodeHttpProxy);
			return {
				enabled: true,
				host: parsed.hostname,
				port: parsed.port ? parseInt(parsed.port) : 8080,
				username: parsed.auth ? parsed.auth.split(':')[0] : undefined,
				password: parsed.auth ? parsed.auth.split(':')[1] : undefined
			};
		}

		return { enabled: false };
	}

	private setupConfigurationListener(): void {
		this.disposables.push(
			vscode.workspace.onDidChangeConfiguration(event => {
				if (event.affectsConfiguration('neoai.useProxySupport') ||
					event.affectsConfiguration('http.proxy')) {
					this.proxySettings = this.loadProxySettings();
				}
			})
		);
	}

	public getProxyOptions(targetUrl: string): https.AgentOptions | http.AgentOptions {
		if (!this.proxySettings.enabled || !this.proxySettings.host) {
			return {};
		}

		const target = url.parse(targetUrl);
		const shouldBypass = this.shouldBypassProxy(target.hostname || '');
		
		if (shouldBypass) {
			return {};
		}

		const proxyOptions: https.AgentOptions | http.AgentOptions = {
			host: this.proxySettings.host,
			port: this.proxySettings.port,
			path: targetUrl,
			headers: {
				'Host': target.hostname
			}
		};

		if (this.proxySettings.username && this.proxySettings.password) {
			const auth = Buffer.from(`${this.proxySettings.username}:${this.proxySettings.password}`).toString('base64');
			proxyOptions.headers = {
				...proxyOptions.headers,
				'Proxy-Authorization': `Basic ${auth}`
			};
		}

		return proxyOptions;
	}

	private shouldBypassProxy(hostname: string): boolean {
		if (!this.proxySettings.bypass) {
			return false;
		}

		return this.proxySettings.bypass.some(pattern => {
			if (pattern.startsWith('*.')) {
				const domain = pattern.substring(2);
				return hostname.endsWith(domain) || hostname === domain;
			}
			return hostname === pattern || hostname.includes(pattern);
		});
	}

	public async makeRequest(url: string, options: https.RequestOptions | http.RequestOptions = {}): Promise<string> {
		return new Promise((resolve, reject) => {
			const protocol = url.startsWith('https') ? https : http;
			
			if (this.proxySettings.enabled && this.proxySettings.host) {
				const proxyOptions = this.getProxyOptions(url);
				options = { ...options, ...proxyOptions };
			}

			const req = protocol.request(url, options, (res) => {
				let data = '';
				
				res.on('data', (chunk) => {
					data += chunk;
				});
				
				res.on('end', () => {
					if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
						resolve(data);
					} else {
						reject(new Error(`HTTP ${res.statusCode}: ${res.statusMessage}`));
					}
				});
			});

			req.on('error', (error) => {
				reject(error);
			});

			if (options.timeout) {
				req.setTimeout(options.timeout, () => {
					req.destroy();
					reject(new Error('Request timeout'));
				});
			}

			req.end();
		});
	}

	public getProxySettings(): ProxySettings {
		return { ...this.proxySettings };
	}

	public async testProxyConnection(): Promise<boolean> {
		if (!this.proxySettings.enabled) {
			return true; // No proxy, so connection should work
		}

		try {
			// Test with a simple request to a reliable endpoint
			await this.makeRequest('https://httpbin.org/ip', { timeout: 5000 });
			return true;
		} catch (error) {
			console.error('Proxy connection test failed:', error);
			return false;
		}
	}

	dispose(): void {
		this.disposables.forEach(disposable => disposable.dispose());
	}
}