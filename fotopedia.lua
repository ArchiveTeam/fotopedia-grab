local url_count = 0
local tries = 0


read_file = function(file)
    if file then
        local f = assert(io.open(file))
        local data = f:read("*all")
        f:close()
        return data
    else
        return ""
    end
end


wget.callbacks.httploop_result = function(url, err, http_stat)
  -- NEW for 2014: Slightly more verbose messages because people keep
  -- complaining that it's not moving or not working
  local status_code = http_stat["statcode"]

  url_count = url_count + 1
  io.stdout:write(url_count .. "=" .. status_code .. " " .. url["url"] .. ".  \r")
  io.stdout:flush()

  if status_code >= 500 or 
  (status_code >= 400 and status_code ~= 404) then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 10")
    tries = tries + 1
    
    if tries >= 10 and (string.match(url["url"], "original%.jpg") or status_code == 410) then
        io.stdout:write("\nI give up...\n")
        io.stdout:flush()
        tries = 0
        return wget.actions.NOTHING
    else
        return wget.actions.CONTINUE
    end
  end
  
  tries = 0

  -- We're okay; sleep a bit (if we have to) and continue
  local sleep_time = 0.1 * (math.random(75, 125) / 100.0)

  if string.match(url["host"], "cdn") or string.match(url["host"], "cloud") then
    -- We should be able to go fast on images since that's what a web browser does
    sleep_time = 0
  end

  if sleep_time > 0.001 then
    os.execute("sleep " .. sleep_time)
  end

  return wget.actions.NOTHING
end


wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
--    print(urlpos["url"]["url"] .. tostring(verdict))

    if string.match(urlpos["url"]["url"], "/bottrap/") then
        return false
    end
    
    if string.match(urlpos["url"]["url"], "%%7B%%7B") or string.match(urlpos["url"]["url"], "{{") or string.match(urlpos["url"]["url"], "%%5C%%22") or string.match(urlpos["url"]["url"], "\\\"") then
        return false
    end

    return verdict
end

wget.callbacks.get_urls = function(file, url, is_css, iri)

    if string.match(url, "/albums/") and string.match(url, "/photos") then
        local current_page = 1
        
        if string.match(url, "page=(%d+)") then
            current_page = tonumber(string.match(url, "page=(%d+)"))
        end
        
    
        local urls = {}
        local html = read_file(file)
        
        if string.match(html, "page=" .. tostring(current_page + 1) .. "[^%d]") then
            local new_url = string.match(url, "http.+/photos") .. "?page=2"
            
            if current_page ~= 1 then
                string.match(url, "http.+/photos%?page=")
                new_url = new_url .. tostring(current_page + 1)
            end
            
            table.insert(urls, { url=new_url, link_expect_html=1 })
        end
        return urls
    end
end


