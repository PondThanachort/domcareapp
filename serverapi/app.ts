import 'dotenv/config'
import express, { ErrorRequestHandler } from 'express'
import cors from 'cors'
import authRoutes from './routes/authRoutes'
import residentRoutes from './routes/residentRoutes'
import requestRoutes from './routes/requestRoutes'
const app = express()
app.use(cors())
app.use(express.json({ limit: '16kb' }))
app.use('/api/auth', authRoutes)
app.use('/api/residents', residentRoutes)
app.use('/api/requests', requestRoutes)
// Coffee product routes are intentionally not mounted in DormCare.
app.use((_req, res) => { res.status(404).json({ status: 'error', message: 'ไม่พบ API ที่ร้องขอ' }) })
const errors: ErrorRequestHandler = (err, _req, res, _next) => {
  const status = err.status === 400 || err.status === 413 ? err.status : 500
  res.status(status).json({ status: 'error', message: status === 500 ? 'เกิดข้อผิดพลาดในระบบ' : 'รูปแบบข้อมูลไม่ถูกต้องหรือมีขนาดใหญ่เกินไป' })
}
app.use(errors)
export default app
