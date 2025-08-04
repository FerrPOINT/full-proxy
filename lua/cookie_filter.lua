-- Cookie Filter for Krea.ai Proxy
-- Rewrites Set-Cookie domain from krea.ai to krea.acm-ai.ru

local function log_cookie_rewrite(original, rewritten)
    ngx.log(ngx.INFO, "Cookie rewrite: ", original, " -> ", rewritten)
end

local function rewrite_cookie_domain(cookie_value)
    if not cookie_value then
        return cookie_value
    end
    
    -- Patterns to match and replace
    local patterns = {
        -- Domain=krea.ai -> Domain=krea.acm-ai.ru
        {pattern = "Domain=krea%.ai", replacement = "Domain=krea.acm-ai.ru"},
        -- Domain=.krea.ai -> Domain=krea.acm-ai.ru
        {pattern = "Domain=%.krea%.ai", replacement = "Domain=krea.acm-ai.ru"},
        -- Domain=www.krea.ai -> Domain=krea.acm-ai.ru
        {pattern = "Domain=www%.krea%.ai", replacement = "Domain=krea.acm-ai.ru"},
        -- Domain=php.krea.ai -> Domain=krea.acm-ai.ru
        {pattern = "Domain=php%.krea%.ai", replacement = "Domain=krea.acm-ai.ru"}
    }
    
    local rewritten = cookie_value
    
    for _, p in ipairs(patterns) do
        local new_value = string.gsub(rewritten, p.pattern, p.replacement)
        if new_value ~= rewritten then
            log_cookie_rewrite(rewritten, new_value)
            rewritten = new_value
        end
    end
    
    return rewritten
end

-- Main header filter function
local function filter_cookies()
    local headers = ngx.resp.get_headers()
    local set_cookie = headers["Set-Cookie"]
    
    if not set_cookie then
        return
    end
    
    -- Handle both single string and table of strings
    local new_cookies = {}
    local has_changes = false
    
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
    
    -- Update headers if changes were made
    if has_changes then
        ngx.header["Set-Cookie"] = new_cookies
        ngx.log(ngx.INFO, "Updated Set-Cookie headers for domain rewrite")
    end
end

-- Execute the filter
filter_cookies() 