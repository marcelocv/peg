require "peg"

print("simples css exemplo\n")

l = peg.locale()

local P = peg.P V = peg.V R = peg.R s = l.space['*'] a = l.alpha an = l.alnum EOF = peg.EOF

local function units( css )
	local t = {}
	for k, u in ipairs(css.unit) do
		t[u.name.string] = {}
		t[u.name.string][u.properties.property.key.string] = u.properties.property.value.string
		for i, v in ipairs(u.properties[2]) do
			t[u.name.string][v.property.key.string] = v.property.value.string
		end
	end
	return t
end

grammar = peg.P{
		'css',
		css = s * V'unit'['*'] * s * EOF % units,
		unit = s * V'name' * s * P'{' * s * V'properties' * s * P'}' * s, 
		properties = V'property' * ( ( s * P';' * s )['+'] * V'property' )['*'] * ( s * P';' * s )['*'],
		property =  V'key' * s * P'=' * s * V'value',
		key = a * an['*'],
		value = an['*'],
		name = a * an['*'],
	}


local i, r = grammar:match([[ 

nome { property = value;; ; property2 = value2; property3 = value3 }

 nome2 { property = value;; ; property2 = value2; property3 = value3 ;; ;  } 
 nome3 { property = value}
 ]])
 

for k,v in pairs( r ) do 
	print(k,v)
	for k,v in pairs( v ) do 
		print(k,v) 
	end
	print()
end


print('==========================================================')
print("json exemplo")

l = peg.locale()

local P = peg.P V = peg.V R = peg.R s = l.space['*'] a = l.alpha 
local an = l.alnum d = l.digit x = l.xdigit c = l.character EOF = peg.EOF

local function null( r ) return nil end

local function f( r ) return false end

local function t( r ) return true end

local function a( r ) 	
	local array = {}
	local elements = r.elements
	if #elements ~= 0 then
		array[1] = elements.value
		for i, e in ipairs(elements[3]) do
			table.insert(array, e.value)
		end
	end
	return array
end

local function o( r )
	local obj = {}
	local members = r.members 
	if #members ~= 0 then
		obj[members.pair.str] = members.pair.value
		for i, m in ipairs(members[3]) do
			obj[m.pair.str] = m.pair.value
		end
	end
	return obj
end

local function str( r ) return r.string:sub(2,-2) end 

local function n( r ) return tonumber(r.string) end 

grammar = peg.P{
	'json',
	json = s * V'value' * s * EOF %function( r ) return r.value end,
	object = P'{' * s * V'members'['?'] * s * P'}',
	members = (P',' * s)['*'] * V'pair' * (( s * P',' * s)['*'] * 
				V'pair')['*'] * ( s * P',' * s)['*'],
	pair = (V'str' %str) * s * P':' * s * V'value',
	array = P'[' * s * V'elements'['?'] * s * P']',
	elements = (P',' * s)['*'] * V'value' * (( s * P',' * s)['*'] * 
				V'value')['*'] * ( s * P',' * s)['*'],
	value = V'str' %str + V'number' %n + V'object' %o + V'array' %a + 
			P'true' %t + P'false' %f + P'null' %null,
	str = (V'str_dq' + V'str_sq'),
	str_dq = P'"' * V'chars_dq' * P'"',
	chars_dq = V'char_dq'['*'],
	char_dq = P'"'['!'] * ( P'\\"' + P'\\\\' + P'\\/' + P'\\b' + P'\\f' + 
				P'\\n' + P'\\r' + P'\\t' + ( P'\\u' * x * x * x * x) + c ),
	str_sq = P"'" * V'chars_sq' * P"'",
	chars_sq = V'char_sq'['*'],
	char_sq = P"'"['!'] * ( P'\\\'' + P'\\\\' + P'\\/' + P'\\b' + P'\\f' + 
				P'\\n' + P'\\r' + P'\\t' + ( P'\\u' * x * x * x * x) + c ),
	number = V'hex' + (V'int' * ( V'frac' * V'exp' + V'frac' + V'exp')['?']),
	int = P'-'['?'] * V'digit'['+'],
	digit = R'09',
	frac = P'.' * V'digit'['+'],
	exp = V'e' * V'digit'['+'],
	e = P'e+' + P'e-' + P'e' + P'E+' + P'E-' + P'E',
	hex = (P'0x' + P'0X') * V'xdigit'['+'],
	xdigit = R'09' + R'af' + R'AF',
 }

print()

local i, r = grammar:match([[ 

  { "a": [true, 444.6, "asdf", { "a": 0x10 }, [ ],['\\1234',-4e4], {},,  ,, ], "b": false } 
   
 ]])

print()

for k,v in pairs( r ) do 
	print(k,v)
	for i,j in pairs( type(v) == 'table' and v or {} ) do 
		print('\t',i,j) 
		for w,z in pairs( type(j) == 'table' and j or {} ) do 
			print('\t\t',w,z) 
		end
	end
end


print('==========================================================')
print("csv exemplo")

l = peg.locale()

local P = peg.P V = peg.V R = peg.R nl = (P'\r\n' + P'\n') 
local s = l.space['*'] EOF = peg.EOF
local a = l.alpha an = l.alnum d = l.digit x = l.xdigit c = l.character


local function no_quoted( r ) return r.string end 
local function quoted( r ) return r.string:sub(2,-2):gsub( '""', '"' ) end
local function lines( r )
	local t = {}
	for i, l in ipairs(r[2]) do
		table.insert(t, {})
		if l.value ~= 0 and #l[2] ~= 0 then 
			table.insert(t[#t], l.value) 
			for i, v in ipairs(l[2]) do
				table.insert(t[#t], v.value)
			end
		end
	end
	return t
end 

grammar = peg.P{
	'csv',
	csv = V'lines' %lines,
	lines = s * V'line'['*'] * s * EOF,
	line = V'value'['?'] * (P',' * V'value')['*'] * nl,
	value =  V'quoted' %quoted + V'no_quoted' %no_quoted,
	no_quoted = (P','['!'] * nl['!'] * c)['+'] ,
	quoted = P'"' * V'chars_dq' * P'"',
	chars_dq = V'char_dq'['*'],
	char_dq = P'""' + P'"'['!'] * c,
}

print()

local i, r = grammar:match([[

Year,Make,Model,Description,Price
1997,Ford,E350,"ac, abs, moon",3000.00
1999,Chevy,"Venture ""Extended Edition""","",4900.00
1999,Chevy,"Venture ""Extended Edition, Very Large""","",5000.00

1996,Jeep,Grand Cherokee,"MUST SELL!
air, moon roof, loaded",4799.00


 ]])

print(i,r)

for k,v in ipairs( r ) do 
	print()
	for i,j in ipairs( v ) do
		print(i,j)
	end
end

