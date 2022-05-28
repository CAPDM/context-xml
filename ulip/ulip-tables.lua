userdata.xmlfunctions = {}

tablealignlookup = {['center'] = 'middle',
                    ['char'] = 'middle',
                    ['justify'] = 'table',
                    ['left'] = 'table',
                    ['right'] = 'flushright'}

-- COLSPEC

function userdata.xmlfunctions.colspec (t)
  -- set lcounter to the ordinal number of the colspec we are in, in order to build a table
  local lcounter = xml.position(t,"/")
  -- add the align attribute (or nil) to the global tablecolspecalign table
  tablecolspecalign[lcounter] = t.at.align
  -- add the colname attribute (or nil) to the global tablecolspecname table (NB name is key)
  tablecolspecname[t.at.colname or 'unknown'] = lcounter
  -- add the colwidth attribute, converted to an integer, to the global tablecolspecwidth table
  -- and add it to the tablecolspecwidthtotal in order to enable later conversion to a TeX width
  if t.at.colwidth == "*" then
    tablecolspecwidth[lcounter] = 1
    tablecolspecwidthtotal = tablecolspecwidthtotal + 1
  else
    tablecolspecwidth[lcounter] = string.match(t.at.colwidth,"[0-9]*")
    tablecolspecwidthtotal = tablecolspecwidthtotal + string.match(t.at.colwidth,"[0-9]*")
  end
  -- add the colsep and rowsep attributes to the relevant global tables
--  tablecolspeccolsep[lcounter] = t.at.colsep
--  tablecolspecrowsep[lcounter] = t.at.rowsep
  logs.pushtarget("logfile")
  logs.writer("colspec width: " .. tablecolspecwidth[lcounter] .. "\n")
  logs.writer("Running total width: " .. tablecolspecwidthtotal .. "\n")
end

-- TBODY

function userdata.xmlfunctions.tbody (t)
  -- convert column widths to TeX widths
  for colcount, colwidth in ipairs(tablecolspecwidth) do
    tablecolspecwidth[colcount] = (colwidth/tablecolspecwidthtotal .. "\\hsize")
    logs.pushtarget("logfile")
    logs.writer("Calculated colspec width: " .. tablecolspecwidth[colcount] .. "\n")
  end
  lxml.flush(t)
end

-- ENTRY

function userdata.xmlfunctions.entry (t)
  -- set trows to the appropriate nr= value based on the morerows attribute (0+1 if not present)
  local trows = (t.at.morerows or 0) + 1
  -- set tcols to the appropriate nc= value based on namest and nameend attributes
  local tcols = 1
  if t.at.namest and t.at.nameend then
    tcols = tablecolspecname[t.at.nameend] - tablecolspecname[t.at.namest] + 1
  end
  -- cellcount holds this entry's position in the row (NB ignores impact of morerows values)
  local cellcount = xml.position(t,"/")
  -- set twidth to the width set in the colspecs for this column
  local twidth = tablecolspecwidth[cellcount]
  -- tcolspecalign is set either by colname matching or by positional matching
  local tcolspecalign
  -- if colname or namest is specified, set tcolspecalign according to the align attribute on the
  -- named colspec (or nil); otherwise set it to the align attribute on the colspec in the same
  -- position as this entry
  if t.at.colname then
    tcolspecalign = xml.attribute(t,"../../../colspec[@colname = '" .. t.at.colname .. "']","align")
  elseif t.at.namest then
    tcolspecalign = xml.attribute(t,"../../../colspec[@colname = '" .. t.at.namest .. "']","align")
  else
    tcolspecalign = tablecolspecalign[cellcount]
  end
  -- now we build the final align value for this cell: this entry's align attribute, or if
  -- that isn't present, the relevant colspec's align attribute, or if that isn't present,
  -- the tgroup's align attribute, or if that isn't present, the default value of 'table'
  local talign = (tablealignlookup[xml.attribute(t,"/","align")] or tablealignlookup[tcolspecalign] or tablealignlookup[xml.attribute(t,"../../../","align")] or 'table')
  -- now onto character alignment; default is none but if align is set to 'char' it is turned on
  local talignchar = 'no'
  if t.at.align == 'char' then talignchar = 'yes' end
  -- finally we output the table cells and their formatting, TH if in thead, TD otherwise
  if intablehead then
    context.bTH({nr=trows,nc=tcols,width=twidth,align=talign})
    lxml.flush(t)
    context.eTH()
  else
    context.bTD({nr=trows,nc=tcols,width=twidth,align=talign,aligncharacter=talignchar})
    lxml.flush(t)
    context.eTD()
  end
end
