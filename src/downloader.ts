import * as path from 'path'
import * as fs from 'fs'
import * as os from 'os'
import { window, workspace } from 'coc.nvim'
import compressing from 'compressing'
import got from 'got'
import tunnel from 'tunnel'

function deleteDirectory(dir: string): void {
  if (fs.existsSync(dir)) {
    fs.readdirSync(dir).forEach(child => {
      let entry = path.join(dir, child)
      if (fs.lstatSync(entry).isDirectory()) {
        deleteDirectory(entry)
      } else {
        fs.unlinkSync(entry)
      }
    })
    fs.rmdirSync(dir)
  }
}

export async function downloadJar(version: string, jarLinkPath: string): Promise<void> {
  let statusItem = window.createStatusBarItem(0, { progress: true })
  statusItem.text = 'Downloading coc-java-dependency jar from github.com'
  statusItem.show()
  let config = workspace.getConfiguration('http')
  let proxy = config.get<string>('proxy', '')
  let options: any = { encoding: null }
  if (proxy) {
    let parts = proxy.replace(/^https?:\/\//, '').split(':', 2)
    options.agent = tunnel.httpsOverHttp({
      proxy: {
        headers: {},
        host: parts[0],
        port: Number(parts[1])
      }
    })
  }

  return new Promise<void>((resolve, reject) => {
    let stream = got.stream(`https://github.com/microsoft/vscode-java-dependency/releases/download/${version}/vscjava.vscode-java-dependency-${version}.vsix`, options)
      .on('downloadProgress', progress => {
        let p = (progress.percent * 100).toFixed(0)
        statusItem.text = `${p}% Downloading coc-java-dependency jar from github.com`
      })

    let tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'coc-java-dependency-'))
    compressing.zip.uncompress(stream as any, tmpDir)
      .then(() => {
        let jarDir = path.dirname(jarLinkPath)
        if (!fs.existsSync(jarDir)) {
          fs.mkdirSync(jarDir)
        }
        let jarName = `com.microsoft.jdtls.ext.core-${version}.jar`
        let jarPath = path.join(jarDir, jarName)
        fs.copyFileSync(path.join(tmpDir, 'extension', 'server', jarName), jarPath)
        fs.symlinkSync(jarPath, jarLinkPath)
        deleteDirectory(tmpDir)
        statusItem.dispose()
        resolve()
      })
      .catch(e => {
        // tslint:disable-next-line: no-console
        console.error(e)
        deleteDirectory(tmpDir)
        statusItem.dispose()
        reject(e)
      })
  })
}
