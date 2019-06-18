local function newData()
	local data = {}
	data.bytes = ""

	function data:append(n, byteSize)
		if not byteSize then byteSize = 1 end

		local bytes = ""
		local h = string.format("%0"..(byteSize*2).."X", n)
		for i=1,byteSize or 1 do 
			local id = (i-1)*2
			bytes = string.char(
				tonumber(
					h:sub(id+1, id+2) , 16
				)
			)..bytes
		end
		self.bytes = self.bytes..bytes
	end

	function data:appendBegin(n, byteSize)
		if not byteSize then byteSize = 1 end
		local bytes = ""
		local h = string.format("%0"..(byteSize*2).."X", n)
		for i=1,byteSize or 1 do 
			local id = (i-1)*2
			bytes = string.char(
				tonumber(
					h:sub(id+1, id+2) , 16
				)
			)..bytes
		end
		self.bytes = bytes..self.bytes
	end

	function data:size()
		return self.bytes:len()
	end

	return data
end

bitmap = {}
bitmap.size = {0,0}
bitmap.map = {}

function bitmap:new(x,y)
	local newbitmap = {}
	for i,v in pairs(self) do
		newbitmap[i] = v
	end
	newbitmap.size = {x,y}

	for sx=1,x do
		newbitmap.map[sx] = {}
		for sy=1,y do
			newbitmap.map[sx][sy] = {0,0,0,0}
		end
	end
	return newbitmap
end

function bitmap:setPixelColor(x,y,color)
	if not self.map[x] or not self.map[x][y] then error("Out of bounds ("..x..", "..y..")".." with size: ("..self.size[1]..", "..self.size[2]..")") end
	self.map[x][y] = color
end

function bitmap:getPixelColor(x,y,color)
	if not self.map[x] or not self.map[x][y] then error("Out of bounds ("..x..", "..y..")".." with size: ("..self.size[1]..", "..self.size[2]..")") end
	return self.map[x][y]
end

--makes a bitmap binary file
function bitmap:binary()
	local PixelData = newData()
	for x=1,self.size[1] do
		for y=1,self.size[2] do
			local color = self.map[x][y]
			PixelData:append(color[1])							--	r
			PixelData:append(color[2])							--	g
			PixelData:append(color[3])							--	b
			PixelData:append(color[4])							--	a
		end
	end
	
	local InfoHeaderData = newData()
	InfoHeaderData:append(self.size[1],4)						--	Horizontal width of bitmap in pixels
	InfoHeaderData:append(self.size[2],4)						--	Vertical height of bitmap in pixels
	InfoHeaderData:append(1,2)									--	Number of Planes (=1)
	InfoHeaderData:append(32,2)									--	32 = 32bit RGBA
	InfoHeaderData:append(0,4)									--	0 = BI_RGB no compression
	InfoHeaderData:append(16,4)									--	(compressed) Size of Image
	InfoHeaderData:append(0,4)									--	horizontal resolution: Pixels/meter
	InfoHeaderData:append(0,4)									--	vertical resolution: Pixels/meter
	InfoHeaderData:append(0,4)									--	Number of actually used colors. For a 8-bit / pixel bitmap this will be 100h or 256.
	InfoHeaderData:append(0,4)									--	0 = all
	InfoHeaderData:appendBegin(InfoHeaderData:size()+4,4)		--	Size of InfoHeader =40 

	local HeaderData = newData()
	HeaderData:append(string.byte("B"))										--	signature
	HeaderData:append(string.byte("M"))										--	signature
	HeaderData:append(InfoHeaderData:size() + PixelData:size() + 14,4)		--	File size in bytes
	HeaderData:append(0,4)													--	unused (=0)
	HeaderData:append(HeaderData:size() + InfoHeaderData:size() + 4,4)		--	Offset from beginning of file to the beginning of the bitmap data

	return HeaderData.bytes..InfoHeaderData.bytes..PixelData.bytes
end

function bitmap:save(at)
	local binaryData = self:binary()
	local file = io.open(at, "wb")
	if file then
		file:write(binaryData)
		return file:close()
	end
	return false
end

--[[

local img = bitmap:new(6,6)
img:setPixelColor(3,3,{255,0,255,255})
img:setPixelColor(6,6,{0,0,255,255})
img:setPixelColor(6,9,{0,0,255,255})
img:setPixelColor(1,1,{255,255,255,255})
img:binary()
local file = io.open("somefile.bmp", "w")
file:write(img:binary())
file:close()

]]