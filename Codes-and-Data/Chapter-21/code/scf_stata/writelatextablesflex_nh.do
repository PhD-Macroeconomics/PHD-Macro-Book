capture file close f${cname}
file open f${i} using "${tabdir}table${cname}.tex", write replace
local nrows = rowsof(table${cname})
local ncols = colsof(table${cname})
local rnames : rownames table${cname} 
file write f${cname} "\centering " _newline 
file write f${cname} "\begin{tabular}{|l|"
//file write f${i} "\begin{longtable}{|l|"
forvalues t = 1(1)`ncols' {
	file write f${cname} "c"
	} 
file write f${cname} "|}" _newline "\hline \hline" _newline
local cnames : colnames table${cname} 
forvalues rc = 1(1)`nrows' {
	local crowname : word `rc' of `rnames'
	file write f${cname} "`y' & \multicolumn{`ncols'}{c|}{`crowname'}  \\ " _newline 
	file write f${cname} " &"
	forvalues t = 1(1)`ncols' {
		local ccolname : word `t' of `cnames'
		if(`t' < `ncols') {
			file write f${cname}  " `ccolname' & " _tab
			}
		else {
			file write f${cname}  " `ccolname' \\ " _newline "\hline" _newline
			}
		} 
	forvalues y = $minyear(3)$maxyear {
		file write f${i} "`y' & " _tab
		forvalues nc = 1(1)`ncols' {
			local cs = table${i}_`y'[`rc',`nc']
			if(`nc' < `ncols') {
				file write f${i} %4.${precision}f (`cs') " & " _tab
				}
			else {
				file write f${i} %4.${precision}f (`cs')  " \\ " _newline
				}
			} 
		} 
	file write f${i} "\hline\hline" _newline
	} 
file write f${i} "\end{tabular}" _newline _newline
//file write f${i} "\end{longtable}" _newline _newline
file close f${i}
