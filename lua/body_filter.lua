-- Body Filter for Dynamic Proxy
-- Replaces all target URLs with proxy domain in response body
-- Professional implementation with error handling and optimization

local ngx = ngx
local string = string

-- Get domains from NGINX variables (set in nginx config)
local target_domain = ngx.var.target_domain or "krea.ai"
local proxy_domain = ngx.var.proxy_domain or "krea.acm-ai.ru"

-- Escape dots for regex patterns
local target_escaped = target_domain:gsub("%.", "%%.")
local proxy_escaped = proxy_domain:gsub("%.", "%%.")

-- Pre-compiled URL replacement patterns for better performance
local URL_PATTERNS = {
    -- Full URLs with protocol (highest priority)
    {pattern = "https://" .. target_escaped, replacement = "https://" .. proxy_domain},
    {pattern = "https://www%." .. target_escaped, replacement = "https://" .. proxy_domain},
    {pattern = "https://php%." .. target_escaped, replacement = "https://" .. proxy_domain},
    {pattern = "http://" .. target_escaped, replacement = "https://" .. proxy_domain},
    {pattern = "http://www%." .. target_escaped, replacement = "https://" .. proxy_domain},
    {pattern = "http://php%." .. target_escaped, replacement = "https://" .. proxy_domain},
    
    -- URLs without protocol
    {pattern = "//" .. target_escaped, replacement = "//" .. proxy_domain},
    {pattern = "//www%." .. target_escaped, replacement = "//" .. proxy_domain},
    {pattern = "//php%." .. target_escaped, replacement = "//" .. proxy_domain},
    
    -- WebSocket URLs
    {pattern = "wss://" .. target_escaped, replacement = "wss://" .. proxy_domain},
    {pattern = "ws://" .. target_escaped, replacement = "wss://" .. proxy_domain},
    
    -- JSON patterns
    {pattern = '"domain":%s*"' .. target_escaped .. '"', replacement = '"domain": "' .. proxy_domain .. '"'},
    {pattern = '"url":%s*"https://' .. target_escaped, replacement = '"url": "https://' .. proxy_domain},
    {pattern = '"origin":%s*"https://' .. target_escaped, replacement = '"origin": "https://' .. proxy_domain .. '"'},
    
    -- Bare domain names (in quotes or as values)
    {pattern = '"' .. target_escaped .. '"', replacement = '"' .. proxy_domain .. '"'},
    {pattern = "'" .. target_escaped .. "'", replacement = "'" .. proxy_domain .. "'"},
    
    -- Generic domain replacement (lowest priority)
    {pattern = target_escaped, replacement = proxy_domain},
}

-- Content types that should be processed
local TEXT_CONTENT_TYPES = {
    ["text/"] = true,
    ["application/json"] = true,
    ["application/javascript"] = true,
    ["text/javascript"] = true,
    ["application/xml"] = true,
    ["text/xml"] = true,
    ["application/xhtml"] = true,
    ["text/html"] = true,
    ["text/css"] = true,
}

-- Optimized URL replacement function
local function replace_urls_in_text(text)
    if not text or type(text) ~= "string" then
        return text
    end
    
    local result = text
    local has_changes = false
    
    -- Apply all patterns in one pass
    for _, pattern_data in ipairs(URL_PATTERNS) do
        local new_result = string.gsub(result, pattern_data.pattern, pattern_data.replacement)
        if new_result ~= result then
            result = new_result
            has_changes = true
        end
    end
    
    if has_changes then
        ngx.log(ngx.INFO, "URLs replaced in response body")
    end
    
    return result
end

-- Check if content type should be processed
local function should_process_content_type(content_type)
    if not content_type then
        return false
    end
    
    for pattern, _ in pairs(TEXT_CONTENT_TYPES) do
        if string.find(content_type, pattern, 1, true) then
            return true
        end
    end
    
    return false
end

-- Main body filter function with proper error handling
local function filter_body()
    local success, err = pcall(function()
        local chunk = ngx.arg[1]
        local eof = ngx.arg[2]
        
        -- Use request-scoped buffer to avoid conflicts
        local buffer = ngx.ctx.response_buffer
        if not buffer then
            buffer = ""
            ngx.ctx.response_buffer = buffer
        end
        
        if chunk then
            ngx.ctx.response_buffer = buffer .. chunk
        end
        
        if eof or #ngx.ctx.response_buffer > 8192 then
            local content_type = ngx.header.content_type or ""
            
            if should_process_content_type(content_type) then
                local processed = replace_urls_in_text(ngx.ctx.response_buffer)
                ngx.arg[1] = processed
            else
                ngx.arg[1] = ngx.ctx.response_buffer
            end
            
            ngx.ctx.response_buffer = ""
        else
            ngx.arg[1] = nil
        end
    end)
    
    if not success then
        ngx.log(ngx.ERR, "Error in body filter: ", err)
        ngx.arg[1] = ngx.arg[1]
    end
end

-- Execute the filter with error handling
local ok, err = pcall(filter_body)
if not ok then
    ngx.log(ngx.ERR, "Failed to execute body filter: ", err)
end 