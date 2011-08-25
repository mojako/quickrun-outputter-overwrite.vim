" ============================================================================
" File:         autoload/quickrun/outputter/overwrite.vim
" Author:       mojako <moja.ojj@gmail.com>
" Last Change:  2011-08-25
" ============================================================================

" s:cpo_save {{{1
let s:cpo_save = &cpo
set cpo&vim
"}}}

let s:outputter = {
  \ 'config': {
  \     'diff': 0,
  \     'diff_split':
  \         '%{winwidth(0) * 2 < winheight(0) * 5 ? "" : "vertical"}',
  \     'diff_into': 0,
  \     'error': 'buffer',
  \     },
  \ }

function! s:outputter.init(session)
    let self._result = ''
endfunction

function! s:outputter.output(data, session)
    let self._result .= a:data
endfunction

function! s:outputter.finish(session)
    if self.config.diff
        let original_data = getline('1', '$')
    endif

    if !empty(self.config.error) && a:session.exit_code
        let outputter = a:session.make_module('outputter', self.config.error)
        call outputter.output(self._result, a:session)
        call outputter.finish(a:session)
        return
    endif

    if a:session.config.mode ==# 'n'
        silent % delete _
        silent $ put =self._result
        silent 1 delete _
    elseif a:session.config.mode ==# 'v' && visualmode() == "\<C-v>"
        let data = split(self._result, '\n')
        silent '<,'> s/\%(\%V.\)\+/\=remove(data, 0)/g
    else
        let data = strpart(getline("'<"), 0, col("'<") - 1)
          \ . substitute(self._result, '\n$', '', '')
          \ . strpart(getline("'>"), col("'>"))
        silent '<,'> delete _
        exe 'silent' line('.') - 1 'put =data'
    endif

    setl modified

    if exists('original_data')
        diffthis

        exe self.config.diff_split 'split'
        edit `='[original]'`
        setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted
        silent $ put =original_data
        silent 1 delete _
        nnoremap <buffer> q :diffoff<CR><C-w>c
        diffthis
        setlocal nomodifiable

        if !self.config.diff_into
            wincmd p
        endif
    endif
endfunction

function! quickrun#outputter#overwrite#new()
    return deepcopy(s:outputter)
endfunction

" s:cpo_save {{{1
let &cpo = s:cpo_save
unlet s:cpo_save
"}}}

" vim: set et sts=4 sw=4 wrap:
