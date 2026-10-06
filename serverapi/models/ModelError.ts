/** Expected domain failure; controllers translate this into an HTTP response. */
export class ModelError extends Error {
  constructor(public readonly status: number, message: string) { super(message) }
}
