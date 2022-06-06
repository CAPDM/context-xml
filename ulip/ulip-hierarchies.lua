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


