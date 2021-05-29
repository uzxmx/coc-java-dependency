let s:jdtls_status = ''

function s:check_jdtls_status()
  if s:jdtls_status != 'Started'
    let s:jdtls_status = CocAction('runCommand', 'java.dependency.getJdtlsStatus')
    if s:jdtls_status != 'Started'
      echomsg 'Java language server has not been started, please check coc-java.'
      return 0
    endif
  endif
  return 1
endfunction

function! java_dep#open()
  if !s:check_jdtls_status() | return | endif
  call s:getTree().open()
endfunction

function! java_dep#close()
  if !s:check_jdtls_status() | return | endif
  call s:getTree().close()
endfunction

function! java_dep#find()
  if !s:check_jdtls_status() | return | endif

  let filename = expand('%')
  let try_jdk = 0
  if filename =~ '^jdt://jarentry/'
    let ary = split(substitute(filename, 'jdt://jarentry/', '', ''), '=')

    if ary[1] =~ '\.jar$'
      let path = [substitute(ary[1], '.*/', '', '')]
    else
      let path = [substitute(ary[1], '.*`', '', '')]
      let try_jdk = 1
    endif
    let ary = split(substitute(ary[0], '?$', '', ''), '/')
    if len(ary) > 1
      call add(path, join(ary[0:-2], '.'))
    endif
    call add(path, ary[-1])
  elseif filename =~ '^jdt://contents/'
    let str = split(substitute(filename, 'jdt://contents/', '', ''), '.class?=')[0]
    if str =~ '^java\.\|jdk\.'
      let try_jdk = 1
    endif
    let path = split(str, '/')
  else
    echoerr 'Unsupported uri: ' . filename
    return
  endif

  let tree = s:getTree()
  call tree.open()

  let childNodes = tree.getChildNodes(tree.getRootNode())
  let i = 0
  while i < len(childNodes)
    let node = childNodes[i]
    let i += 1

    if node.getName() =~ '^JRE System Library' && !try_jdk | continue | endif

    let found = tree.findNodeByPath(path, node)
    if !empty(found)
      call tree.focus(found)
      break
    endif
  endwhile
endfunction

function s:getTree()
  if !exists('s:tree')
    let s:tree = widgets#tree#new('JavaDependency', {
          \ 'winWidth': 50,
          \ 'getRootNode': function('s:getRootNode'),
          \ 'getChildNodes': function('s:getChildNodes'),
          \ 'openLeafNode': function('s:openLeafNode'),
          \ }, {
          \ 's': { 'func': function('s:open'), 'args': ['vs'] },
          \ 't': { 'func': function('s:open'), 'args': ['tabe'] },
          \ })
  endif
  return s:tree
endfunction

let s:NodeKindProject = 2
let s:NodeKindContainer = 3
let s:NodeKindPackageRoot = 4
let s:NodeKindPackage = 5
let s:NodeKindPrimaryType = 6
let s:NodeKindFolder = 7
let s:NodeKindFile = 8

function s:getProjectUri()
  return 'file://' . g:WorkspaceFolders[0]
endfunction

function s:getRootNode(tree)
  let rootNode = widgets#tree#inter_node#newRoot('Java Dependency')
  let childNodes = []
  let res = CocAction('runCommand', 'java.getPackageData', { 'kind': s:NodeKindProject, 'projectUri': s:getProjectUri() })
  for i in res
    if i.entryKind == 5
      call add(childNodes, widgets#tree#inter_node#new(i.name, i))
    endif
  endfor

  call rootNode.setChildNodes(childNodes)
  call rootNode.open()
  return rootNode
endfunction

function! s:getChildNodes(node)
  let node = a:node
  let data = node.getData()
  if data.kind == s:NodeKindPackageRoot
    let res = CocAction('runCommand', 'java.getPackageData', { 'kind': data.kind, 'projectUri': s:getProjectUri(), 'rootPath': data.path, 'handlerIdentifier': data.handlerIdentifier, 'isHierarchicalView': v:true })
  elseif data.kind == s:NodeKindPackage
    let res = CocAction('runCommand', 'java.getPackageData', { 'kind': data.kind, 'projectUri': s:getProjectUri(), 'path': data.name, 'handlerIdentifier': data.handlerIdentifier })
  else
    let res = CocAction('runCommand', 'java.getPackageData', { 'kind': data.kind, 'projectUri': s:getProjectUri(), 'path': data.path })
  endif

  let childNodes = []
  for i in res
    if i.kind == s:NodeKindFile || i.kind == s:NodeKindPrimaryType
      call add(childNodes, widgets#tree#leaf_node#new(i.name, i))
    elseif i.kind == s:NodeKindProject || i.kind == s:NodeKindContainer || i.kind == s:NodeKindPackageRoot || i.kind == s:NodeKindPackage || i.kind == s:NodeKindFolder
      call add(childNodes, widgets#tree#inter_node#new(i.name, i))
    endif
  endfor
  call node.setChildNodes(childNodes)
endfunction

function! s:parse_utf8(str, start)
  let str = a:str
  let hex = '0x' . str[a:start : a:start + 1]
  if hex <= 0x7f
    let remainder_len = 0
  elseif hex <= 0xdf
    let mask = 0x1f
    let remainder_len = 1
  elseif hex <= 0xef
    let mask = 0x0f
    let remainder_len = 2
  elseif hex <= 0xf7
    let mask = 0x07
    let remainder_len = 3
  elseif hex <= 0xfb
    let mask = 0x03
    let remainder_len = 4
  elseif hex <= 0xfd
    let mask = 0x01
    let remainder_len = 5
  else
    throw 'Invalid UTF-8 prefix ' . hex
  endif

  if remainder_len > 0
    let hex = and(hex, mask) * float2nr(pow(64, remainder_len))
    let i = 0
    while i < remainder_len
      let i += 1
      let idx = a:start + i * 3
      let hex += and('0x' . str[idx : idx + 1], 0x3f) * float2nr(pow(64, remainder_len - i))
    endwhile
  endif

  return [hex, 2 + remainder_len * 3]
endfunction

function! s:urldecode(str)
  let str = a:str
  let decoded = ''
  let l:len = len(str)
  let i = 0
  while i < l:len
    let ch = str[i]
    let i += 1
    if ch ==# '%'
      let [hex, read_count] = s:parse_utf8(str, i)
      let i += read_count
      let decoded .= nr2char(hex)
    else
      let decoded .= ch
    endif
  endwhile
  return decoded
endfunction

function! s:openLeafNode(tree, node)
  call s:open_with_mode(a:node.getData().uri, 'e')
endfunction

function! s:open(tree, mode)
  let node = a:tree.findCurrentNode()
  if !empty(node) && node.isLeaf()
    call s:open_with_mode(node.getData().uri, a:mode)
  endif
endfunction

function s:open_with_mode(uri, mode)
  wincmd p
  execute a:mode ' ' fnameescape(s:urldecode(a:uri))
endfunction
