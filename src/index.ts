import { ExtensionContext, commands, extensions, window } from "coc.nvim"
import * as path from 'path'
import * as fs from 'fs'

import { downloadJar } from './downloader'

const jarVersion = '0.18.3'
let jarLinkPath: string

export async function activate(context: ExtensionContext): Promise<void> {
    await activateExtension("", context)

    jarLinkPath = path.join(context.extensionPath, 'server', 'com.microsoft.jdtls.ext.core.jar')
    if (!fs.existsSync(jarLinkPath)) {
      download(jarVersion)
    }
}

async function activateExtension(_operationId: string, context: ExtensionContext): Promise<void> {
  context.subscriptions.push(commands.registerCommand('java.dependency.downloadJdtlsExtension', version => {
    if (!version) {
      version = jarVersion
    }
    checkAndDownload(version)
  }))

  context.subscriptions.push(commands.registerCommand('java.dependency.getJdtlsStatus', () => {
    // @ts-ignore
    let extensionAPI = extensions.getExtensionApi('coc-java')
    return extensionAPI.status
  }, null, true))
}

function download(version: string) {
  downloadJar(version, jarLinkPath).then(() => {
    // @ts-ignore
    extensions.reloadExtension('coc-java-dependency')
  })
}

function checkAndDownload(version: string) {
  if (fs.existsSync(jarLinkPath)) {
    let targetPath = fs.readlinkSync(jarLinkPath)
    let basename = path.basename(targetPath)
    let result = basename.match(/^com.microsoft.jdtls.ext.core-(.*).jar$/)
    if (result && result[1] === version) {
      window.showMessage(`Version ${version} already exists.`)
      return
    }
    fs.unlinkSync(jarLinkPath)
    fs.unlinkSync(targetPath)
  }
  download(version)
}
