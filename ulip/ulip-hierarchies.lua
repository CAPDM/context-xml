function userdata.xmlfunctions.chapter (t)
   local lnumberoverride = xml.attribute(t,"/","number-override")
   if lnumberoverride then
      lnumberoverride = lnumberoverride - 1
      context.setupheadnumber({"chapter"}, {lnumberoverride})
   end
   context.startchapter({reference = t.at.id, title = xml.text(t, '/title')})
   lxml.all(t, "/!title")
   context.stopchapter()
   context.page({yes})
end

function userdata.xmlfunctions.blank (t)
   local bwidth = (t.at.size or 10) / 2
   local bheight = t.at.rows or "1"
   if bheight == "1" then
      context.framed({ width = (bwidth .. "em"), frame = "off", bottomframe = "on"}, '')
   else
      context.framed({ width = "\\hsize", height = (bheight .. "\\lineheight"), frame = "on"}, '')
   end
end

function userdata.xmlfunctions.videodata (t)
   local lfileref = ("https:" .. t.at.fileref)
   lfileref = lfileref:gsub('/rss/', '/images/')
   lfileref = lfileref:gsub('.rss', '.jpg')
   context('\\llap{\\color[ULIPblue]{\\tfc\\symbol[fontawesome][film]}\\quad}\\vskip-24pt')
   context('\\externalfigure[' .. lfileref .. '][width=.7\\hsize,framecolor=ULIPblue,frame=on]')
end


