require("peg")
print("simples css exemplo")]

l = peg.locale()

local P = peg.P V = peg.V R = peg.R s = l.space['*'] a = l.alpha an = l.alnum

local function units( css )
	local t = {}
	print(css.unit.string)
	for k, u in ipairs(css.unit) do
		t[u.name.string] = {}
		print(u.name.string, u.properties)
		t[u.name.string][u.properties.property.key.string] = u.properties.property.value.string
		for i, v in ipairs(u.properties[2]) do
			t[u.name.string][v.property.key.string] = v.property.value.string
		end
	end
	return t
end

grammar = peg.P{
		'css',
		css = s * V'unit'['*'] * s % units,
		unit = s * V'name' * s * P'{' * s * V'properties' * s * P'}' * s, 
		properties = V'property' * ( ( s * P';' * s )['+'] * V'property' )['*'] * ( s * P';' * s )['*'],
		property =  V'key' * s * P'=' * s * V'value',
		key = a * an['*'],
		value = an['*'],
		name = a * an['*'],
	}

print()
--print(grammar:match('ba'))

local i, r = grammar:match([[ 

nome { property = value;; ; property2 = value; property3 = value }

 nome2 { property = value;; ; property2 = value; property3 = value ;; ;  } 
 nome3 { property = value}
 ]])
print(r)

for k,v in pairs( r ) do 
	print(k,v)
	for k,v in pairs( v ) do 
		print(k,v) 
	end
end

print('==========================================================')
print("json exemplo")

l = peg.locale()

local P = peg.P V = peg.V R = peg.R s = l.space['*'] a = l.alpha an = l.alnum d = l.digit x = l.xdigit

local function null( r ) return nil end

local function f( r ) return false end

local function t( r ) return true end

local function a( r ) 	
	local array = {}
	local elements = r.elements
	if #elements ~= 0 then
		array[1] = type(elements.value) == 'table' and elements.value.string or elements.value
		for i, e in ipairs(elements[3]) do
			table.insert(array, type(e.value) == 'table' and e.value.string or e.value)
		end
	end
	return array
end

local function o( r )
	local obj = {}
	local members = r.members 
	if #members ~= 0 then
		obj[members.pair.str] = type(members.pair.value) == 'table' and members.pair.value.string or members.pair.value
		for i, m in ipairs(members[3]) do
			obj[m.pair.str] = type(m.pair.value) == 'table' and m.pair.value.string or m.pair.value
		end
	end
	return obj
end

local function str( r ) return r.string:sub(2,-2) end 

local function n( r ) return tonumber(r.string) end 

grammar = peg.P{
	'json',
	json = s * V'value' * s %function( r ) return r.value end,
	object = P'{' * s * V'members'['?'] * s * P'}',
    members = (P',' * s)['*'] * V'pair' * (( s * P',' * s)['*'] * V'pair')['*'] * ( s * P',' * s)['*'],
	pair = (V'str' %str) * s * P':' * s * V'value',
	array = P'[' * s * V'elements'['?'] * s * P']',
	elements = (P',' * s)['*'] * V'value' * (( s * P',' * s)['*'] * V'value')['*'] * ( s * P',' * s)['*'],
    value = V'str' %str + V'number' %n + V'object' %o + V'array' %a + 
			P'true' %t+ P'false' %f + P'null' %null,
	str = (V'str_dq' + V'str_sq'),
	str_dq = P'"' * V'chars_dq' * P'"',
	chars_dq = V'char_dq'['*'],
    char_dq = P'"'['!'] * ( P'\\"' + P'\\\\' + P'\\/' + P'\\b' + P'\\f' + P'\\n' + P'\\r' + P'\\t' + 
			( P'\\u' * x * x * x * x) + l.unicode ),
	str_sq = P"'" * V'chars_sq' * P"'",
	chars_sq = V'char_sq'['*'],
    char_sq = P"'"['!'] * ( P'\\\'' + P'\\\\' + P'\\/' + P'\\b' + P'\\f' + P'\\n' + P'\\r' + P'\\t' + 
			( P'\\u' * x * x * x * x) + l.unicode ),
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
--print(grammar:match('ba'))

local i, r = grammar:match([[ 

  { "a": [true, 444.6, "asdf", { "a": 0x10 }, [ ],['\\1234',-4e4], {},,  ,, ], "b": false } 
   
 ]])
print(i, r, 'aaaaaa')
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



