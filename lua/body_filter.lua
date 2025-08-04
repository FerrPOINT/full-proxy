-- Body Filter for Krea.ai Proxy
-- Replaces all krea.ai URLs with krea.acm-ai.ru in response body

local ngx = ngx

-- Buffer for accumulating response chunks
local response_buffer = ""

-- URL replacement patterns
local url_patterns = {
    -- Full URLs with protocol
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
    
    -- Bare domain names (in quotes or as values)
    {pattern = '"krea%.ai"', replacement = '"krea.acm-ai.ru"'},
    {pattern = "'krea%.ai'", replacement = "'krea.acm-ai.ru'"},
    {pattern = "krea%.ai", replacement = "krea.acm-ai.ru"},
    
    -- JSON patterns
    {pattern = '"domain":%s*"krea%.ai"', replacement = '"domain": "krea.acm-ai.ru"'},
    {pattern = '"url":%s*"https://krea%.ai', replacement = '"url": "https://krea.acm-ai.ru'},
    {pattern = '"origin":%s*"https://krea%.ai', replacement = '"origin": "https://krea.acm-ai.ru'},
    
    -- WebSocket URLs
    {pattern = "wss://krea%.ai", replacement = "wss://krea.acm-ai.ru"},
    {pattern = "ws://krea%.ai", replacement = "wss://krea.acm-ai.ru"},
}

local function replace_urls_in_text(text)
    if not text then
        return text
    end
    
    local result = text
    
    for _, pattern in ipairs(url_patterns) do
        local new_result = string.gsub(result, pattern.pattern, pattern.replacement)
        if new_result ~= result then
            ngx.log(ngx.INFO, "URL replacement: ", pattern.pattern, " -> ", pattern.replacement)
            result = new_result
        end
    end
    
    return result
end

-- Main body filter function
local function filter_body()
    local chunk = ngx.arg[1]
    local eof = ngx.arg[2]
    
    if chunk then
        -- Accumulate chunks
        response_buffer = response_buffer .. chunk
    end
    
    -- Process accumulated buffer on EOF or when buffer is large enough
    if eof or #response_buffer > 8192 then
        local content_type = ngx.header.content_type or ""
        
        -- Only process text-based content types
        if string.find(content_type, "text/") or 
           string.find(content_type, "application/json") or
           string.find(content_type, "application/javascript") or
           string.find(content_type, "text/javascript") or
           string.find(content_type, "application/xml") or
           string.find(content_type, "text/xml") or
           string.find(content_type, "application/xhtml") then
            
            local processed = replace_urls_in_text(response_buffer)
            
            -- Output processed content
            ngx.arg[1] = processed
        else
            -- For non-text content, output as-is
            ngx.arg[1] = response_buffer
        end
        
        -- Clear buffer
        response_buffer = ""
    else
        -- Don't output anything yet, just accumulate
        ngx.arg[1] = nil
    end
end

-- Execute the filter
filter_body() 