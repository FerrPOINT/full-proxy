-- Cookie Filter for Dynamic Proxy
-- Rewrites Set-Cookie domain from target to proxy domain
-- Professional implementation with error handling and optimization

local ngx = ngx
local string = string

-- Get domains from NGINX variables (set in nginx config)
local target_domain = ngx.var.target_domain or "krea.ai"
local proxy_domain = ngx.var.proxy_domain or "krea.acm-ai.ru"

-- Pre-compiled patterns for better performance
local COOKIE_PATTERNS = {
    {pattern = "Domain=" .. target_domain:gsub("%.", "%%."), replacement = "Domain=" .. proxy_domain},
    {pattern = "Domain=%." .. target_domain:gsub("%.", "%%."), replacement = "Domain=" .. proxy_domain},
    {pattern = "Domain=www%." .. target_domain:gsub("%.", "%%."), replacement = "Domain=" .. proxy_domain},
    {pattern = "Domain=php%." .. target_domain:gsub("%.", "%%."), replacement = "Domain=" .. proxy_domain},
    -- Additional patterns for www subdomain
    {pattern = "Domain=www%." .. target_domain:gsub("%.", "%%."), replacement = "Domain=" .. proxy_domain},
    {pattern = "Domain=%." .. target_domain:gsub("%.", "%%."), replacement = "Domain=" .. proxy_domain}
}

-- Location header patterns for redirects
local LOCATION_PATTERNS = {
    {pattern = "https://" .. target_domain:gsub("%.", "%%."), replacement = "https://" .. proxy_domain},
    {pattern = "http://" .. target_domain:gsub("%.", "%%."), replacement = "https://" .. proxy_domain},
    {pattern = "https://www%." .. target_domain:gsub("%.", "%%."), replacement = "https://" .. proxy_domain},
    {pattern = "http://www%." .. target_domain:gsub("%.", "%%."), replacement = "https://" .. proxy_domain}
}

-- Function to rewrite Set-Cookie headers
local function rewrite_cookies()
    local headers = ngx.resp.get_headers()
    if not headers then
        return
    end
    
    local set_cookie = headers["Set-Cookie"]
    if not set_cookie then
        return
    end
    
    -- Handle both single string and table of strings
    local cookies = type(set_cookie) == "table" and set_cookie or {set_cookie}
    local modified = false
    
    for i, cookie in ipairs(cookies) do
        if type(cookie) == "string" then
            local original_cookie = cookie
            for _, pattern_data in ipairs(COOKIE_PATTERNS) do
                cookie = cookie:gsub(pattern_data.pattern, pattern_data.replacement)
            end
            
            if cookie ~= original_cookie then
                cookies[i] = cookie
                modified = true
                ngx.log(ngx.INFO, "Cookie domain rewritten: ", original_cookie, " -> ", cookie)
            end
        end
    end
    
    if modified then
        -- Remove original Set-Cookie header
        ngx.header["Set-Cookie"] = nil
        
        -- Add rewritten cookies
        for _, cookie in ipairs(cookies) do
            ngx.header["Set-Cookie"] = cookie
        end
    end
end

-- Function to rewrite Location headers for redirects
local function rewrite_location()
    local location = ngx.header["Location"]
    if not location then
        return
    end
    
    local original_location = location
    for _, pattern_data in ipairs(LOCATION_PATTERNS) do
        location = location:gsub(pattern_data.pattern, pattern_data.replacement)
    end
    
    if location ~= original_location then
        ngx.header["Location"] = location
        ngx.log(ngx.INFO, "Location header rewritten: ", original_location, " -> ", location)
    end
end

-- Main execution with error handling
local ok, err = pcall(function()
    rewrite_cookies()
    rewrite_location()
end)
if not ok then
    ngx.log(ngx.ERR, "Error in cookie filter: ", err)
end 