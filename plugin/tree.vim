if exists('g:loaded_coc_java_dependency')
  finish
endif
let g:loaded_coc_java_dependency = 1

command! JavaDependencyOpen call java_dep#open()
command! JavaDependencyClose call java_dep#close()
command! JavaDependencyFind call java_dep#find()
