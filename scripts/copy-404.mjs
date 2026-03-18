import { copyFile } from 'node:fs/promises'
import { resolve } from 'node:path'

const root = process.cwd()
const src = resolve(root, 'dist', 'index.html')
const dest = resolve(root, 'dist', '404.html')

await copyFile(src, dest)
