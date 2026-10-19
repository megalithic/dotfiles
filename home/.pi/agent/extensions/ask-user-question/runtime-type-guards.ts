export function isString(value: unknown): value is string {
	return Object.prototype.toString.call(value) === "[object String]";
}

export function isBoolean(value: unknown): value is boolean {
	return Object.prototype.toString.call(value) === "[object Boolean]";
}

type Callable = (...args: never[]) => void;

/** Like `typeof value === "function"`: async and generator functions tag as AsyncFunction etc., so no toString tag. */
export function isFunction(value: unknown): value is Callable {
	return value instanceof Function;
}

export function isObject(value: unknown): value is object {
	return Object.prototype.toString.call(value) === "[object Object]";
}
