-- Cookie Filter for Krea.ai Proxy
-- Rewrites Set-Cookie domain from krea.ai to krea.acm-ai.ru
-- Professional implementation with error handling and optimization

local ngx = ngx
local string = string

-- Pre-compiled patterns for better performance
local COOKIE_PATTERNS = {
    -- Domain=krea.ai -> Domain=krea.acm-ai.ru
    {pattern = "Domain=krea%.ai", replacement = "Domain=krea.acm-ai.ru"},
    -- Domain=.krea.ai -> Domain=krea.acm-ai.ru  
    {pattern = "Domain=%.krea%.ai", replacement = "Domain=krea.acm-ai.ru"},
    -- Domain=www.krea.ai -> Domain=krea.acm-ai.ru
    {pattern = "Domain=www%.krea%.ai", replacement = "Domain=krea.acm-ai.ru"},
    -- Domain=php.krea.ai -> Domain=krea.acm-ai.ru
    {pattern = "Domain=php%.krea%.ai", replacement = "Domain=krea.acm-ai.ru"}
}

-- Optimized cookie domain rewriting function
local function rewrite_cookie_domain(cookie_value)
    if not cookie_value or type(cookie_value) ~= "string" then
        return cookie_value
    end
    
    local rewritten = cookie_value
    local has_changes = false
    
    -- Apply all patterns in one pass
    for _, pattern_data in ipairs(COOKIE_PATTERNS) do
        local new_value = string.gsub(rewritten, pattern_data.pattern, pattern_data.replacement)
        if new_value ~= rewritten then
            rewritten = new_value
            has_changes = true
        end
    end
    
    if has_changes then
        ngx.log(ngx.INFO, "Cookie domain rewritten: ", cookie_value, " -> ", rewritten)
    end
    
    return rewritten
end

-- Main header filter function with proper error handling
local function filter_cookies()
    local success, err = pcall(function()
        -- Get Set-Cookie headers directly from ngx.header
        local set_cookie = ngx.header["Set-Cookie"]
        
        if not set_cookie then
            return
        end
        
        local new_cookies = {}
        local has_changes = false
        
        -- Handle both single string and table of strings
        if type(set_cookie) == "table" then
            -- Multiple Set-Cookie headers
            for i, cookie in ipairs(set_cookie) do
                local rewritten = rewrite_cookie_domain(cookie)
                if rewritten ~= cookie then
                    has_changes = true
                end
                new_cookies[i] = rewritten
            end
        else
            -- Single Set-Cookie header
            local rewritten = rewrite_cookie_domain(set_cookie)
            if rewritten ~= set_cookie then
                has_changes = true
            end
            new_cookies = rewritten
        end
        
        -- Update headers only if changes were made
        if has_changes then
            ngx.header["Set-Cookie"] = new_cookies
            ngx.log(ngx.INFO, "Updated Set-Cookie headers for domain rewrite")
        end
    end)
    
    if not success then
        ngx.log(ngx.ERR, "Error in cookie filter: ", err)
    end
end

-- Execute the filter with error handling
local ok, err = pcall(filter_cookies)
if not ok then
    ngx.log(ngx.ERR, "Failed to execute cookie filter: ", err)
end 