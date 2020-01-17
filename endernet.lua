-- To use in your program, the following lines must be added.
-- os.loadAPI("endernet")
-- os.pullEvent = endernet.middle
-- os.pullEventRaw = endernet.middleRaw
--
-- This API exposes the following methods (NOTE: all topics MUST begin with "/", otherwise they will be dropped with 404 error code)
-- send(string topic, string message) -- Sends a message to the specified topic -- Returns maximum number of possibly connected clients (Not all that useful, but can be informative)
-- subscribe(string topic) -- Subscribes to a topic in order to receive messages from it -- Returns nil
-- assert(string topic) -- Asserts a topic, renewing a request in case its connection is dropped
-- unsubscribe(string topic) -- Unsubscribes from a topic -- Returns nil
-- receive() -- Receives message from any of the subscribed topics -- Returns topic, message
-- middle(event) -- Meant to replace os.pullEvent, and handles http events in order to keep them alive
-- middleRaw(event) -- Same as above, for os.pullEventRaw

-- Define global api modifications to help later
function table.contains(table, element)
	for _, value in pairs(table) do
		if value == element then
			return true
		end
	end
	return false
end

-- Define local variables
local subdTopics = {}
local baseUrl = "http://example.com/ccnet"
local sendUrl = "/send"
local query = "/query"
local dataToSend = "?message="

-- Define functions
function send(topic,message) -- Sends a message to a topic
	local hhandle = http.get(baseUrl..sendUrl..topic..dataToSend..textutils.urlEncode(message))
	return tonumber(hhandle.readAll())
end

function subscribe(topic) -- Subscribes to a topic
	if not table.contains(subdTopics,topic) then
		table.insert(subdTopics,topic)
		http.request(baseUrl..query..topic)
	end
end

function assert(topic) -- Asserts a topic, renewing it's connection in case it dropped
	http.request(baseUrl..query..topic)
end

function unsubscribe(topic) -- Unsubscribes from a topic
	for k,v in pairs(subdTopics) do
		if v==topic then
			table.remove(subdTopics,k)
		end
	end
end

function receive() -- Returns topic, message
	local event = {middle("endernet_receive")}
	return event[2],event[3]
end

function middle(eventName) -- os.pullEvent = endernet.middle
	-- Define variables that I'd prefer not to leak out but are evaluated later
	local event
	local topic
	local message

	-- Yield should work, because if it's overwritten, the computer won't work
	event = {coroutine.yield()}
	if event[1]=="terminate" then
		error("Terminated")
	end

	-- Parse the event
	if event[1]=="http_success" then
		topic = string.gsub(event[2],baseUrl..query,"")
		if table.contains(subdTopics,topic) then
			http.request(event[2])
		end
		if eventName==nil or eventName=="endernet_receive" then
			if string.find(event[2],baseUrl..query)~=nil then
				message = event[3].readAll()
				return "endernet_receive",topic,message
			else
				return table.unpack(event)
			end
		else
			return middle(eventName)
		end
	elseif event[1]=="http_failure" then
		if table.contains(subdTopics,string.gsub(event[2],baseUrl..query,"")) then
			http.request(event[2])
		end
		return middle(eventName)
	else
		if eventName==nil or event[1]==eventName then
			return table.unpack(event)
		else
			return middle(eventName)
		end
	end

end

function middleRaw(eventName) -- os.pullEvent = endernet.middle
	-- Define variables that I'd prefer not to leak out but are evaluated later
	local event
	local topic
	local message

	-- Yield should work, because if it's overwritten, the computer won't work
	event = {coroutine.yield()}

	-- Parse the event
	if event[1]=="http_success" then
		topic = string.gsub(event[2],baseUrl..query,"")
		if table.contains(subdTopics,topic) then
			http.request(event[2])
		end
		if eventName==nil or eventName=="endernet_receive" then
			if string.find(event[2],baseUrl..query)~=nil then
				message = event[3].readAll()
				return "endernet_receive",topic,message
			else
				return table.unpack(event)
			end
		else
			return middle(eventName)
		end
	elseif event[1]=="http_failure" then
		if table.contains(subdTopics,string.gsub(event[2],baseUrl..query,"")) then
			http.request(event[2])
		end
		return middle(eventName)
	else
		if eventName==nil or event[1]==eventName then
			return table.unpack(event)
		else
			return middle(eventName)
		end
	end

end
