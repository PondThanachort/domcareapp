import 'dotenv/config'
export function jwtSecret(): string {
  const secret = process.env.JWT_SECRET
  if (!secret || secret.length < 32) throw new Error('JWT_SECRET must contain at least 32 characters')
  return secret
}
export const tokenOptions = { algorithm: 'HS256' as const, expiresIn: '8h' as const, issuer: 'dormcare-api', audience: 'dormcare-app' }
