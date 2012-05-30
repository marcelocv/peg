-- Marcelo Cimeno Vizaco
-- marcelo.vizaco@gmail.com
-- http://en.wikipedia.org/wiki/Parsing_expression_grammar

module(..., package.seeall)

	
local function Or( a, b )

	return MakePeg{
		type = 'pattern_or',
		__match = function( p, i, str, vars )
			local ia, ra, name = a:__match( i, str, vars )
			if ia then 
				return ia, ra, name
			else 
				local ib, rb, name = b:__match( i, str, vars )
				if ib then
					return ib, rb, name
				else
					return false
				end
			end
		end
	}
end

local function And( a, b )

	return MakePeg{
		type = 'pattern_and',
		__match = function( p, i, str, vars )
			local ia, ra, name = a:__match( i, str, vars )
			if ia then
				local r = a.type == 'pattern_and' and ra or { ra }
				if name then
					r[name] = ra					
				end
				local ib, rb, name = b:__match( ia, str, vars )
				if ib then
					if name then
						r[name] = rb					
					end
					table.insert( r, rb )
					r.string = str:sub( i, ib - 1 )
					return ib, r
				end
			end
			return false
		end
	}
end

local function ZeroOrMore( a )

	return MakePeg{
		type = 'pattern_zero_or_more',
		__match = function( p, i, str, vars )
			local i1, r1, name = a:__match( i, str, vars )
			local r = { r1 }
			if i1 then 
				local i2 = i1
				while i2 do
					local r2
					i1 = i2; i2, r2, name = a:__match( i1, str, vars )
					if i2 then 
						r[ #r + 1 ] = r2 
					end
				end
			end
			r.string = str:sub( i, (i1 or i) - 1 )
			return i1 or i, r, name
		end
	}
end

local function OneOrMore( a )
	
	return MakePeg{
		type = 'pattern_one_or_more',
		__match = function( p, i, str, vars )
			local i1, r1, name = a:__match( i, str, vars )
			local r = { r1 }
			if i1 then 		
				local i2 = i1
				while i2 do 
					local r2
					i1 = i2; i2, r2 = a:__match( i1, str, vars )
					if i2 then
						r[ #r + 1 ] = r2
					end
				end
				r.string = str:sub( i, i1 - 1 )
				return i1, r, name
			else
				return false
			end
		end
	}
end

local function Optional( a )

	return MakePeg{
		type = 'pattern_optional',
		__match = function( p, i, str, vars )
			local i2, r, name = a:__match( i, str, vars )
			if i2 then return i2, r, name else return i, '', name end
		end
	}
end

local function OrPredicate( a )

	return MakePeg{
		type = 'pattern_or_predicate',
		__match = function( p, i, str, vars )
			local i1, r, name = a:__match( i, str, vars )
			if i1 then
				return false
			else
				return i, '', name
			end
		end
	}
end

local function AndPredicate( a )

	return MakePeg{
		type = 'pattern_and_predicate',
		__match = function( p, i, str, vars )
			local i1, r, name = a:__match( i, str, vars )
			if i1 then
				return i, '', name
			else
				return false
			end
		end
	}
end

local function Unaries( Tbl, Key )

	local t = {
		['!'] = OrPredicate,
		['&'] = AndPredicate,
		['*'] = ZeroOrMore,
		['?'] = Optional,
		['+'] = OneOrMore,
	}
	assert( t[Key], 'Dont understand such symbol.' .. (key or '') )
	return t[Key]( Tbl )
end

local function Variable( name )

	return MakePeg{
		name = name,
		type = 'pattern_variable',
		__match = function( p, i, str, vars )
			local i1, r = vars[name]:__match( i, str, vars )
			return i1, r, name
		end
	}
end

local function Range( range )

	return MakePeg{
		type = 'pattern_range',
		__match = function( p, i, str )
			if string.find( str:sub(i,i), '[' .. range:sub(1,1) .. '-' .. range:sub(2,2) .. ']' ) then
				return i + 1, str:sub(i,i)
			else
				return false
			end
		end
	}
end

local function Set( set )

	return MakePeg{
		type = 'pattern_set',
		__match = function( p, i, str )
			if set:find( str:sub(i,i) ) then
				return i + 1, str:sub(i,i)
			else
				return false
			end
		end
	}
end

local function Pattern( a )

	return MakePeg{
		type = 'pattern',
		vars = type(a) == 'table' and a or nil,
		__match = function( p, i, str, vars )
			if type(a) == 'string' then
				if str:sub( i, i + #a - 1 ) == a then
					return i + #a, a
				else
					return false
				end
			elseif type(a) == 'number' then
				if #str:sub( i, i + a - 1 ) == a then
					return i + a, str:sub( i, i + a - 1 )
				else
					return false
				end
			elseif type(a) == 'boolean' then
				if a then
					return i, ''
				else
					return false
				end
			elseif a.type and a.type:sub( 1, #'pattern' ) == 'pattern' then
				return a:__match( i, str, {} )
			else
				return a[a[1]]:__match( i, str, a )
			end
		end
	}
end

local function DoFunction( pattern, func )
	assert( type(func) == 'function', 'Second argument must be a function.' )
	return MakePeg{
		type = 'pattern',
		__match = function( p, i, str, vars )
			local i1, r, name = pattern:__match( i, str, vars )
			if i1 then
				return i1, func( r ), name
			else
				return false
			end
		end
	}
end

function MakePeg( tfunctions )

	t = {}
	local __MetaPeg = {
		__index = Unaries,
		__mod = DoFunction,
		__add = Or,
		__mul = And,
	}

	for k, v in pairs(tfunctions or {}) do
		t[k] = v
	end
	t.match = function(a, str) 
		i, r = a:__match(1, str, nil); 
		return i, type(r) == 'table' and r or { r }  
	end
	return setmetatable( t, __MetaPeg )
end

local function locale( new_locale )

	local l = {
		alnum = MakePeg{
			type = 'pattern',
			__match = function( p, i, str )
				return string.find( str:sub(i,i), '[%w]' ) and i+1, str:sub(i,i)
			end
		},
		alpha = MakePeg{
			type = 'pattern',
			__match = function( p, i, str )
				return string.find( str:sub(i,i), '[%a]' ) and i+1, str:sub(i,i)
			end
		}, 
		cntrl = MakePeg{
			type = 'pattern',
			__match = function( p, i, str )
				return string.find( str:sub(i,i), '[%c]' ) and i+1, str:sub(i,i)
			end
		},
		digit = MakePeg{
			type = 'pattern',
			__match = function( p, i, str )
				return string.find( str:sub(i,i), '[%d]' ) and i+1, str:sub(i,i)
			end
		},
		graph = MakePeg{
			type = 'pattern',
			__match = function( p, i, str )
				return string.find( str.char(i), '[%w%p]' ) and i+1, str:sub(i,i)
			end
		},
		lower = MakePeg{
			type = 'pattern',
			__match = function( p, i, str )
				return string.find( str:sub(i,i), '[%l]' ) and i+1, str:sub(i,i)
			end
		},
		punct = MakePeg{
			type = 'pattern',
			__match = function( p, i, str )
				return string.find( str:sub(i,i), '[%p]' ) and i+1, str:sub(i,i)
			end
		},
		space = MakePeg{
			type = 'pattern',
			__match = function( p, i, str )
				return string.find( str:sub(i,i), '[%s]' ) and i+1, str:sub(i,i)
			end
		},
		upper = MakePeg{
			type = 'pattern',
			__match = function( p, i, str )
				return string.find( str:sub(i,i), '[%u]' ) and i+1, str:sub(i,i)
			end
		},
		xdigit = MakePeg{
			type = 'pattern',
			__match = function( p, i, str )
				return string.find( str:sub(i,i), '[abcdefABCDEF%d]' ) and i+1, str:sub(i,i)
			end
		},
		character = MakePeg{
			type = 'pattern',
			__match = P(1).__match
		},
	}
	if new_locale then
		for k, v in pairs( new_locale ) do
			l[k] = v
		end
	end
	return l
end

EOF = MakePeg{
	type = 'pattern',
	__match = function( p, i, str )
		return i > #str and i, ''
	end	
}

local __mt = {
	V = Variable,
	R = Range,
	S = Set,
	P = Pattern,
	EOF = EOF,
	locale = locale
}
for k, v in pairs( __mt ) do
	peg[k] = v
end

