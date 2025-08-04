-- Body Filter for Krea.ai Proxy
-- Replaces all krea.ai URLs with krea.acm-ai.ru in response body
-- Professional implementation with error handling and optimization

local ngx = ngx
local string = string

-- Pre-compiled URL replacement patterns for better performance
local URL_PATTERNS = {
    -- Full URLs with protocol (highest priority)
    {pattern = "https://krea%.ai", replacement = "https://krea.acm-ai.ru"},
    {pattern = "https://www%.krea%.ai", replacement = "https://krea.acm-ai.ru"},
    {pattern = "https://php%.krea%.ai", replacement = "https://krea.acm-ai.ru"},
    {pattern = "http://krea%.ai", replacement = "https://krea.acm-ai.ru"},
    {pattern = "http://www%.krea%.ai", replacement = "https://krea.acm-ai.ru"},
    {pattern = "http://php%.krea%.ai", replacement = "https://krea.acm-ai.ru"},
    
    -- URLs without protocol
    {pattern = "//krea%.ai", replacement = "//krea.acm-ai.ru"},
    {pattern = "//www%.krea%.ai", replacement = "//krea.acm-ai.ru"},
    {pattern = "//php%.krea%.ai", replacement = "//krea.acm-ai.ru"},
    
    -- WebSocket URLs
    {pattern = "wss://krea%.ai", replacement = "wss://krea.acm-ai.ru"},
    {pattern = "ws://krea%.ai", replacement = "wss://krea.acm-ai.ru"},
    
    -- JSON patterns
    {pattern = '"domain":%s*"krea%.ai"', replacement = '"domain": "krea.acm-ai.ru"'},
    {pattern = '"url":%s*"https://krea%.ai', replacement = '"url": "https://krea.acm-ai.ru'},
    {pattern = '"origin":%s*"https://krea%.ai', replacement = '"origin": "https://krea.acm-ai.ru'},
    
    -- Bare domain names (in quotes or as values)
    {pattern = '"krea%.ai"', replacement = '"krea.acm-ai.ru"'},
    {pattern = "'krea%.ai'", replacement = "'krea.acm-ai.ru'"},
    
    -- Generic domain replacement (lowest priority)
    {pattern = "krea%.ai", replacement = "krea.acm-ai.ru"},
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
            -- Accumulate chunks
            ngx.ctx.response_buffer = buffer .. chunk
        end
        
        -- Process accumulated buffer on EOF or when buffer is large enough
        if eof or #ngx.ctx.response_buffer > 8192 then
            local content_type = ngx.header.content_type or ""
            
            -- Only process text-based content types
            if should_process_content_type(content_type) then
                local processed = replace_urls_in_text(ngx.ctx.response_buffer)
                ngx.arg[1] = processed
            else
                -- For non-text content, output as-is
                ngx.arg[1] = ngx.ctx.response_buffer
            end
            
            -- Clear buffer
            ngx.ctx.response_buffer = ""
        else
            -- Don't output anything yet, just accumulate
            ngx.arg[1] = nil
        end
    end)
    
    if not success then
        ngx.log(ngx.ERR, "Error in body filter: ", err)
        -- On error, pass through original content
        ngx.arg[1] = ngx.arg[1]
    end
end

-- Execute the filter with error handling
local ok, err = pcall(filter_body)
if not ok then
    ngx.log(ngx.ERR, "Failed to execute body filter: ", err)
end 