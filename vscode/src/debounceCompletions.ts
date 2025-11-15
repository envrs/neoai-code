export function debounceCompletions<T extends (...args: any[]) => any>(
	func: T,
	wait: number
): T {
	let timeout: NodeJS.Timeout | undefined;
	
	return ((...args: Parameters<T>) => {
		const later = () => {
			timeout = undefined;
			return func(...args);
		};
		
		if (timeout) {
			clearTimeout(timeout);
		}
		
		if (wait > 0) {
			timeout = setTimeout(later, wait);
			return Promise.resolve([]);
		} else {
			return func(...args);
		}
	}) as T;
}