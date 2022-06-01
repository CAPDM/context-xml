userdata.xmlfunctions = {}

tablealignlookup = {['center'] = 'middle',
   ['char'] = 'middle',
   ['justify'] = 'table',
   ['left'] = 'table',
   ['right'] = 'flushright'}

-- may extend later
tablerowseplookup = {['0'] = 'off', ['1'] = 'on'}
tablecolseplookup = {['0'] = 'off', ['1'] = 'on'}

--TGROUP

function userdata.xmlfunctions.tgroup (t)
   -- reset the global stuff which is used in the entry calculations
   tablecolspecalign = {}
   tablecolspecname = {}
   tablecolspecwidth = {}
   tablecolspecwidthtotal = (0)
   tablecolspecconverted = (false)
   tablecolspeccolsep = {}
   tablecolspecrowsep = {}
   tablerowtracker = (0)
   
   tablerowtotal = xml.count(t, "/thead/row") or 0
   tablerowtotal = tablerowtotal + xml.count(t, "/tbody/row")

   lxml.flush(t)
   
end

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
   tablecolspeccolsep[lcounter] = t.at.colsep
   tablecolspecrowsep[lcounter] = t.at.rowsep

end

-- ROW

function userdata.xmlfunctions.row (t)
   if not tablecolspecconverted then
      for colcount, colwidth in ipairs(tablecolspecwidth) do
	 tablecolspecwidth[colcount] = (colwidth/tablecolspecwidthtotal)
	 context.setupTABLE(column, colcount, {width = tablecolspecwidth[colcount]})
	 logs.pushtarget("logfile")
	 logs.writer("Calculated colspec width: " .. tablecolspecwidth[colcount] .. "\n")
      end
      context.bTR()
      for colcount, colwidth in ipairs(tablecolspecwidth) do
	 context.bTD({width = (colwidth .. "\\TableWidth")})
	 context.eTD()
      end
      context.eTR()
      tablecolspecconverted = true
   end
   tablerowtracker = tablerowtracker + 1
   context.bTR()
   lxml.flush(t)
   context.eTR()
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
   local twidth
   -- if this is a column span then the entry needs to be the total width of all included columns
   if t.at.namest and t.at.nameend then
      twidth = (tablecolspecwidth[(tablecolspecname[t.at.namest])] .. "\\TableWidth")
      logs.writer("First named column span width: " .. twidth .. "\n")
      -- local twidthtotal = 0
      -- local twidthcount = cellcount - 1
      -- -- start at the current column and keep adding to the width until you reach the end of the
      -- -- span
      -- repeat
      -- 	 twidthcount = twidthcount + 1
      -- 	 twidthtotal = twidthtotal + tonumber(tablecolspecwidth[twidthcount])
      -- 	 logs.pushtarget("logfile")
      -- 	 logs.writer("Column span width running total: " .. twidthtotal .. "\n")
      -- until tablecolspecname[t.at.nameend] == twidthcount
      -- -- now append \TableWidth to create the final twidth value
      -- twidth = (twidthtotal .. "\\TableWidth")
      -- logs.writer("Totalled column span width: " .. twidth .. "\n")
   -- otherwise, if this entry has a colname specified, use the named column's colspec width
   elseif t.at.colname then
      twidth = (tablecolspecwidth[(tablecolspecname[t.at.colname])] .. "\\TableWidth")
      logs.writer("Named column span width: " .. twidth .. "\n")
   else
      twidth = (tablecolspecwidth[cellcount] .. "\\TableWidth")
      logs.writer("Counted column span width: " .. twidth .. "\n")
   end
   
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

   -- default trowsep is off
   local trowsep = 'off'
   -- if the enclosing table/informaltable has a frame attribute set to all, topbot or bottom,
   -- and this is the last row in the table, then that overrides any rowsep value
   if (tablerowtracker == tablerowtotal) and ((xml.attribute(t,"../../../../","frame") == 'bottom') or (xml.attribute(t,"../../../../","frame") == 'topbot') or (xml.attribute(t,"../../../../","frame") == 'all')) then
      trowsep = 'on'
   else
      -- otherwise we build the rowsep: this entry's rowsep attribute, or if that isn't present,
      -- the row's rowsep attribute, or if that isn't present, the relevant colspec's rowsep
      -- attribute, or if that isn't present, the tgroup's rowsep attribute, or if that isn't
      -- present, the table/informaltable's rowsep attribute, or if that isn't present, the
      -- default value of '0' (no rowsep)
      trowsep = (tablerowseplookup[xml.attribute(t,"/","rowsep")] or tablerowseplookup[xml.attribute(t,"../","rowsep")] or tablerowseplookup[tcolspecrowsep] or tablerowseplookup[xml.attribute(t,"../../../","rowsep")] or tablerowseplookup[xml.attribute(t,"../../../../","rowsep")] or 'off')
   end
   
   -- and now the colsep: this entry's colsep attribute, or if that isn't present, the relevant
   -- colspec's colsep attribute, or if that isn't present, the tgroup's colsep attribute, or
   -- if that isn't present, the table/informaltable's colsep attribute, or if that isn't
   -- present, the default value of '0' (no colsep)
   local tcolsep = (tablecolseplookup[xml.attribute(t,"/","colsep")] or tablecolseplookup[tcolspeccolsep] or tablecolseplookup[xml.attribute(t,"../../../","colsep")] or tablecolseplookup[xml.attribute(t,"../../../../","colsep")] or 'off')
   
   --frame testing
   local ttopframe = 'off'
   if (tablerowtracker == 1) and ((xml.attribute(t,"../../../../","frame") == 'top') or (xml.attribute(t,"../../../../","frame") == 'topbot') or (xml.attribute(t,"../../../../","frame") == 'all')) then
      ttopframe='on'
   end

   -- finally we output the table cells and their formatting, TH if in thead, TD otherwise
   if intablehead then
      context.bTH({nr=trows,nc=tcols,width=twidth,align=talign,bottomframe=trowsep,rightframe=tcolsep,topframe=ttopframe})
      lxml.flush(t)
      context.eTH()
   else
      context.bTD({nr=trows,nc=tcols,width=twidth,align=talign,aligncharacter=talignchar,bottomframe=trowsep,rightframe=tcolsep,topframe=ttopframe})
      lxml.flush(t)
      context.eTD()
   end
end
