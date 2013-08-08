" ---------[ INFORMATION ]---------
"
" Vim plugin for emulating Windows Notepad's logging functionality, with
" additional capablity to log duration.
" Maintainer:  Talha Mansoor <talha131@gmail.com>
" Version:     1.0
" Last Change: 2013 August 08
"
" --------[ HOW TO USE IT ]--------
"
" Create a new text file. Insert .LOG. Save it. Then reopen it.
" Now you have a timestamped log file. 
"
" Example:
"
"     .LOG
"     Sun Jul 14 17:38:44 2013
"     First entry of the day
"     Sun Jul 14 17:46:11 2013
"     Replied to customer emails.
"     Sun Jul 14 18:41:43 2013
"     Skype session with remote team.
"
" If LogpadLogDuration is set then time elapsed since last event will also be
" added
"
" Example:
"
"     .LOG
"     Sun Jul 14 17:38:44 2013
"     First entry of the day
"     Sun Jul 14 17:46:11 2013
"     Time elapsed: 7 min 27 sec 
"     Replied to customer emails.
"     Sun Jul 14 18:41:43 2013
"     Time elapsed: 55 min 32 sec 
"     Skype session with remote team.
"
"
" Now you can see that your Skype session took 55 min. Your replied to emails within
" 7 min. Without this feature, you will have to do mental maths to calculate the
" time it took you to do a work.
"
" --------[ CONFIGURATION ]--------
"
" Optional values to set in your .vimrc file:
"
" let LogpadEnabled = [ 0 / 1 ]
"   >> enables/disables logpad
"   >> default value: 1
"
" let LogpadInsert = [ 0 / 1 ]
"   >> automatically enables insert mode when a new log entry is created
"   >> default value: 0
"
" let LogpadLineBreak = [ 0 / 1 ]
"   >> adds an empty line before a new log entry
"   >> default value: 0 (Windows Notepad behavior)
"
" let LogpadIgnoreNotes = [ 0 / 1 ]
"   >> allows adding notes before the first log entry
"   >> default value: 0
"
" let LogpadIgnoreReadOnly = [ 0 / 1 ]
"   >> allows logpad to ignore a file's read-only flag
"   >> default value: 0
"
" let LogpadLogDuration = [ 0 / 1 ]
"   >> adds the duration elapsed since last timestamp under the new timestamp
"   >> default value: 0
"
" -----------[ CHANGES ]-----------
"
" Version 1.0
" New Feature: 
"     Insert time elapsed since last timestamp. 
"     This is useful if user needs to check how much time has passed since the last entry.
" Bug fixes:
" Two bug fixes in Version 1.4 of original logpad plugin
"     1. If user sets LogpadInsert = 1 then Logpad will start insert mode and make 
"     it default. When insert made is default, keys like Esc are not mapped. You are 
"     forced to use Ctrl-O or Ctrl-L to execute normal mode commands. It is understandable 
"     that user will not want to change Vim behaviour. All he wants is to be in the insert mode
"     so that he can start typing immediately.
"     2. Logpad relies on a timestamp format to check whether there are
"     timestamps below .LOG keyword or not. 
"     The way timestamp format is created programmatically gives you two
"     types of timestamps. One for dates that have single digit and two for
"     those dates that have two digit. This, in turn, creates a bug. If Logpad
"     gets a timestamp for double digit date, like when the user is using the
"     plugin on 12th of the month, and the date under .LOG is single digit,
"     like 9 th of the month, Logpad will consider that date as a note and
"     will not further log timestamps.
"
" -----------[ CREDITS ]-----------
"
" This plugin is a fork of logpad plugin by Sven Knurr <der_tuxman@arcor.de> available at:
" http://vim.sourceforge.net/scripts/script.php?script_id=2775

"
" ---------[ HERE WE GO! ]---------


function! s:CalculateMonth(month)
   if (match(a:month, 'Jan\c') != -1) 
       return 0
   elseif (match(a:month, 'Feb\c') != -1)
       return 1
   elseif (match(a:month, 'Mar\c') != -1)
       return 2
   elseif (match(a:month, 'Apr\c') != -1)
       return 3
   elseif (match(a:month, 'May\c') != -1)
       return 4
   elseif (match(a:month, 'Jun\c') != -1)
       return 5
   elseif (match(a:month, 'Jul\c') != -1)
       return 6
   elseif (match(a:month, 'Aug\c') != -1)
       return 7
   elseif (match(a:month, 'Sep\c') != -1)
       return 8
   elseif (match(a:month, 'Oct\c') != -1)
       return 9
   elseif (match(a:month, 'Nov\c') != -1)
       return 10
   elseif (match(a:month, 'Dec\c') != -1)
       return 11
   endif

   return -1
endfunction


function! s:SplitStringTime(timeString)
    let splitedTime = split(a:timeString)
    let month = s:CalculateMonth(splitedTime[1])
    let day = splitedTime[2]
    let year = splitedTime[4]
    
    let time = split(splitedTime[3], ':')
    let hour = time[0]
    let min = time[1]
    let sec = time[2]

    return [year, month, day, hour, min, sec]
endfunction


function! s:ConvertTimeToSeconds(timestamp)
    " First calculate seconds for the years elapsed
    " A day consists of 86400 seconds
    let seconds = (a:timestamp[0] - 2010) * 365 * 86400
    let seconds += (a:timestamp[1] * 30 * 86400) + (a:timestamp[2] * 86400) + (a:timestamp[3] * 3600) + (a:timestamp[4] * 60) + (a:timestamp[5])
    return seconds
endfunction


function! s:ConvertSecondsToDate(seconds)
    let num_seconds = a:seconds

    let year = num_seconds / (365*60*60*24)
    let num_seconds -= year * (365*60*60*24)
    let month = num_seconds / (30*60*60*24)
    let num_seconds -= month * (30*60*60*24)
    let days = num_seconds / (60*60*24)
    let num_seconds -= days * (60*60*24)
    let hours = num_seconds / (60*60)
    let num_seconds -= hours * (60*60)
    let minutes = num_seconds / 60
    let num_seconds -= minutes * 60

    return [year, month, days, hours, minutes, num_seconds]
endfunction


function! s:CalculateTimeElapsed(oldTimestamp, newTimestamp)
    let [year, month, day, hour, min, sec] = s:SplitStringTime(a:oldTimestamp)
    let [Year, Month, Day, Hour, Min, Sec] = s:SplitStringTime(a:newTimestamp)

    let old_seconds = s:ConvertTimeToSeconds([year, month, day, hour, min, sec])
    let new_seconds = s:ConvertTimeToSeconds([Year, Month, Day, Hour, Min, Sec])

    let diff_seconds = abs(new_seconds - old_seconds)

    return s:ConvertSecondsToDate(diff_seconds)
endfunction


function! s:TimeElapsedStr(timeElapsed)
    let timeElapsedString = ""

    if (a:timeElapsed[0] > 0)
        let timeElapsedString = a:timeElapsed[0] . " year "
    endif

    if (a:timeElapsed[1] > 0)
        let timeElapsedString = timeElapsedString . a:timeElapsed[1] . " month "
    endif

    if (a:timeElapsed[2] > 0)
        let timeElapsedString = timeElapsedString . a:timeElapsed[2] . " day "
    endif

    if (a:timeElapsed[3] > 0)
        let timeElapsedString = timeElapsedString . a:timeElapsed[3] . " hour "
    endif

    if (a:timeElapsed[4] > 0)
        let timeElapsedString = timeElapsedString . a:timeElapsed[4] . " min "
    endif

    if (a:timeElapsed[5] > 0)
        let timeElapsedString = timeElapsedString . a:timeElapsed[5] . " sec "
    endif

    if (len(timeElapsedString) > 0)
        let timeElapsedString = "Time elapsed: " . timeElapsedString
    endif

    return timeElapsedString
endfunction


function! LogpadInit()
    " check the configuration, set it (and exit) if needed
    if !exists('g:LogpadEnabled')        | let g:LogpadEnabled        = 1 | endif
    if !exists('g:LogpadInsert')         | let g:LogpadInsert         = 0 | endif
    if !exists('g:LogpadLineBreak')      | let g:LogpadLineBreak      = 0 | endif
    if !exists('g:LogpadIgnoreNotes')    | let g:LogpadIgnoreNotes    = 0 | endif
    if !exists('g:LogpadIgnoreReadOnly') | let g:LogpadIgnoreReadOnly = 0 | endif
    if !exists('g:LogpadLogDuration')    | let g:LogpadLogDuration = 0    | endif

    if g:LogpadEnabled == 0                          | return             | endif
    if g:LogpadIgnoreReadOnly == 0 && &readonly == 1 | return             | endif

    " main part
    if getline(1) =~ '^\.LOG$'

        " 3 letters for day name
        " space
        " 3 letter for month
        " space
        " an optional space that occurs if day is single digit
        " one or two digit for day
        " space
        " hour:min:seconds
        " space
        " year
        let s:timestampformat = '\(\a\{3}\s\)\{2}\s\{0,1}\d\{1,2}\s\(\d\{2}:\)\{2}\d\{2}\s\d\{4}'

        if nextnonblank(2) > 0
            if getline(nextnonblank(2)) !~ s:timestampformat && g:LogpadIgnoreNotes == 0
                " there are following lines, but these aren't timestamps,
                " obviously the user doesn't want to create a log then...
                return
            endif
        endif

        " add a new entry
        let s:failvar = 0
        while s:failvar != 1
            if g:LogpadLineBreak == 1
                " add a single empty divider line if requested
                let s:failvar = append(line('$'), "")
            endif

            " if g:LogpadLogDuration is defined then
            " move the cursor to the end of file.
            " search for the pattern
            " if pattern is present read it
            " calculate duration
            " log duration
            let latestTime = strftime('%c')
            let s:duration = ""

            if g:LogpadLogDuration == 1
                call cursor(line('$'), 0)
                let linenumber = search(s:timestampformat, 'b')
                if (linenumber != 0)
                    let lastTimestamp = getline(linenumber)
                    let s:duration = s:TimeElapsedStr(s:CalculateTimeElapsed(lastTimestamp, latestTime))
                endif
            endif

            let s:failvar = append(line('$'), latestTime)


            if (len(s:duration) > 0)
                let s:failvar = append(line('$'), s:duration)
            endif

            let s:failvar = append(line('$'), "")

            " go to the last line
            call cursor(line('$'), 0)

            " if we're here, everything worked so far; let's exit
            let s:failvar = 1
        endwhile

        " enter insert mode if enabled
        if g:LogpadInsert == 1
            execute  ":startinsert" 
        endif
    endif
endfunction

autocmd BufReadPost * call LogpadInit()

