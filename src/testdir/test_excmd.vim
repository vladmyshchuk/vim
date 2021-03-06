" Tests for various Ex commands.

func Test_ex_delete()
  new
  call setline(1, ['a', 'b', 'c'])
  2
  " :dl is :delete with the "l" flag, not :dlist
  .dl
  call assert_equal(['a', 'c'], getline(1, 2))
endfunc

func Test_range_error()
  call assert_fails(':.echo 1', 'E481:')
  call assert_fails(':$echo 1', 'E481:')
  call assert_fails(':1,2echo 1', 'E481:')
  call assert_fails(':+1echo 1', 'E481:')
  call assert_fails(':/1/echo 1', 'E481:')
  call assert_fails(':\/echo 1', 'E481:')
  normal vv
  call assert_fails(":'<,'>echo 1", 'E481:')
endfunc

func Test_buffers_lastused()
  call test_settime(localtime() - 2000) " middle
  edit bufa
  enew
  call test_settime(localtime() - 10)   " newest
  edit bufb
  enew
  call test_settime(1550010000)	        " oldest
  edit bufc
  enew
  call test_settime(0)
  enew

  let ls = split(execute('buffers t', 'silent!'), '\n')
  let bufs = ls->map({i,v->split(v, '"\s*')[1:2]})
  call assert_equal(['bufb', 'bufa', 'bufc'], bufs[1:]->map({i,v->v[0]}))
  call assert_match('1[0-3] seconds ago', bufs[1][1])
  call assert_match('\d\d:\d\d:\d\d', bufs[2][1])
  call assert_match('2019/02/1\d \d\d:\d\d:00', bufs[3][1])

  bwipeout bufa
  bwipeout bufb
  bwipeout bufc
endfunc

" Test for the :copy command
func Test_copy()
  new

  call setline(1, ['L1', 'L2', 'L3', 'L4'])
  " copy lines in a range to inside the range
  1,3copy 2
  call assert_equal(['L1', 'L2', 'L1', 'L2', 'L3', 'L3', 'L4'], getline(1, 7))

  close!
endfunc

" Test for the :file command
func Test_file_cmd()
  call assert_fails('3file', 'E474:')
  call assert_fails('0,0file', 'E474:')
  call assert_fails('0file abc', 'E474:')
endfunc

" Test for the :drop command
func Test_drop_cmd()
  call writefile(['L1', 'L2'], 'Xfile')
  enew | only
  drop Xfile
  call assert_equal('L2', getline(2))
  " Test for switching to an existing window
  below new
  drop Xfile
  call assert_equal(1, winnr())
  " Test for splitting the current window
  enew | only
  set modified
  drop Xfile
  call assert_equal(2, winnr('$'))
  " Check for setting the argument list
  call assert_equal(['Xfile'], argv())
  enew | only!
  call delete('Xfile')
endfunc

" Test for the :append command
func Test_append_cmd()
  new
  call setline(1, ['  L1'])
  call feedkeys(":append\<CR>  L2\<CR>  L3\<CR>.\<CR>", 'xt')
  call assert_equal(['  L1', '  L2', '  L3'], getline(1, '$'))
  %delete _
  " append after a specific line
  call setline(1, ['  L1', '  L2', '  L3'])
  call feedkeys(":2append\<CR>  L4\<CR>  L5\<CR>.\<CR>", 'xt')
  call assert_equal(['  L1', '  L2', '  L4', '  L5', '  L3'], getline(1, '$'))
  %delete _
  " append with toggling 'autoindent'
  call setline(1, ['  L1'])
  call feedkeys(":append!\<CR>  L2\<CR>  L3\<CR>.\<CR>", 'xt')
  call assert_equal(['  L1', '    L2', '      L3'], getline(1, '$'))
  call assert_false(&autoindent)
  %delete _
  " append with 'autoindent' set and toggling 'autoindent'
  set autoindent
  call setline(1, ['  L1'])
  call feedkeys(":append!\<CR>  L2\<CR>  L3\<CR>.\<CR>", 'xt')
  call assert_equal(['  L1', '  L2', '  L3'], getline(1, '$'))
  call assert_true(&autoindent)
  set autoindent&
  close!
endfunc

" Test for the :insert command
func Test_insert_cmd()
  new
  call setline(1, ['  L1'])
  call feedkeys(":insert\<CR>  L2\<CR>  L3\<CR>.\<CR>", 'xt')
  call assert_equal(['  L2', '  L3', '  L1'], getline(1, '$'))
  %delete _
  " insert before a specific line
  call setline(1, ['  L1', '  L2', '  L3'])
  call feedkeys(":2insert\<CR>  L4\<CR>  L5\<CR>.\<CR>", 'xt')
  call assert_equal(['  L1', '  L4', '  L5', '  L2', '  L3'], getline(1, '$'))
  %delete _
  " insert with toggling 'autoindent'
  call setline(1, ['  L1'])
  call feedkeys(":insert!\<CR>  L2\<CR>  L3\<CR>.\<CR>", 'xt')
  call assert_equal(['    L2', '      L3', '  L1'], getline(1, '$'))
  call assert_false(&autoindent)
  %delete _
  " insert with 'autoindent' set and toggling 'autoindent'
  set autoindent
  call setline(1, ['  L1'])
  call feedkeys(":insert!\<CR>  L2\<CR>  L3\<CR>.\<CR>", 'xt')
  call assert_equal(['  L2', '  L3', '  L1'], getline(1, '$'))
  call assert_true(&autoindent)
  set autoindent&
  close!
endfunc

" Test for the :change command
func Test_change_cmd()
  new
  call setline(1, ['  L1', 'L2', 'L3'])
  call feedkeys(":change\<CR>  L4\<CR>  L5\<CR>.\<CR>", 'xt')
  call assert_equal(['  L4', '  L5', 'L2', 'L3'], getline(1, '$'))
  %delete _
  " change a specific line
  call setline(1, ['  L1', '  L2', '  L3'])
  call feedkeys(":2change\<CR>  L4\<CR>  L5\<CR>.\<CR>", 'xt')
  call assert_equal(['  L1', '  L4', '  L5', '  L3'], getline(1, '$'))
  %delete _
  " change with toggling 'autoindent'
  call setline(1, ['  L1', 'L2', 'L3'])
  call feedkeys(":change!\<CR>  L4\<CR>  L5\<CR>.\<CR>", 'xt')
  call assert_equal(['    L4', '      L5', 'L2', 'L3'], getline(1, '$'))
  call assert_false(&autoindent)
  %delete _
  " change with 'autoindent' set and toggling 'autoindent'
  set autoindent
  call setline(1, ['  L1', 'L2', 'L3'])
  call feedkeys(":change!\<CR>  L4\<CR>  L5\<CR>.\<CR>", 'xt')
  call assert_equal(['  L4', '  L5', 'L2', 'L3'], getline(1, '$'))
  call assert_true(&autoindent)
  set autoindent&
  close!
endfunc

" vim: shiftwidth=2 sts=2 expandtab
