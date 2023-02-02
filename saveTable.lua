--This is licensed software. please visit http://www.justfly.solutions/index.php/licenses/2-lua-scripts-license
--Copyright 2016-2018 to Khadija.el.Bekkaoui and/or Entel Consulting BVBA
--

local table,fileName=...

local indent = ""

local function outputTable (tbl)
  if not (type(tbl)=="table") then 
    return tbl
  end
  indent=indent .. "   "
  local res= "\n" .. indent .. "{\n" 
  for k, v in pairs(tbl) do
    if type(k) == "number" then
      k="[" .. k .. "]"
    end
    if type(v) == "table" then
      res=res .. indent .. k .. " = " .. outputTable(v) .. ",\n" 
    elseif type(v) == "function" then
    elseif type(v) == "string" then
      res=res .. indent .. k .. " = '" .. v .. "',\n" 
    elseif type(v) == "boolean" then
      if v then res=res .. indent .. k .. " = true,\n"
      else res=res .. indent .. k .. " = false,\n"
      end
    else
      res=res .. indent .. k .. " = " .. v .. ",\n" 
    end
  end
  res = res ..   indent .. "}"
  indent=string.sub(indent,4) 
  return res 
end  

if io and (type(table) == "table") then
   
  local f = io.open(fileName, "w")


  io.write(f,"return " .. outputTable(table))
  io.close(f)
    
  f=nil

end

