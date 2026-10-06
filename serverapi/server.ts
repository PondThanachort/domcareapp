import app from './app'
import { jwtSecret } from './utils/auth'
jwtSecret()
const port = Number(process.env.PORT || 3000)
app.listen(port, () => console.log(`DormCare API listening on port ${port}`))
