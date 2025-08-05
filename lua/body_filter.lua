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
    {pattern = "http://" .. target_escaped, replacement = "https://" .. proxy_domain},
    {pattern = "//" .. target_escaped, replacement = "//" .. proxy_domain},
    
    -- www subdomain patterns
    {pattern = "https://www%." .. target_escaped, replacement = "https://" .. proxy_domain},
    {pattern = "http://www%." .. target_escaped, replacement = "https://" .. proxy_domain},
    {pattern = "//www%." .. target_escaped, replacement = "//" .. proxy_domain},
    
    -- Relative URLs
    {pattern = "/" .. target_escaped, replacement = "/" .. proxy_domain},
    {pattern = "/www%." .. target_escaped, replacement = "/" .. proxy_domain},
    
    -- JavaScript/TypeScript specific patterns
    {pattern = "baseURL%s*=%s*['\"]https://" .. target_escaped, replacement = "baseURL = '" .. proxy_domain},
    {pattern = "baseURL%s*=%s*['\"]http://" .. target_escaped, replacement = "baseURL = '" .. proxy_domain},
    {pattern = "baseURL%s*=%s*['\"]//" .. target_escaped, replacement = "baseURL = '" .. proxy_domain},
    
    -- www subdomain in JS patterns
    {pattern = "baseURL%s*=%s*['\"]https://www%." .. target_escaped, replacement = "baseURL = '" .. proxy_domain},
    {pattern = "baseURL%s*=%s*['\"]http://www%." .. target_escaped, replacement = "baseURL = '" .. proxy_domain},
    {pattern = "baseURL%s*=%s*['\"]//www%." .. target_escaped, replacement = "baseURL = '" .. proxy_domain},
    
    -- Fetch and XHR patterns
    {pattern = "fetch%s*%(%s*['\"]https://" .. target_escaped, replacement = "fetch('https://" .. proxy_domain},
    {pattern = "fetch%s*%(%s*['\"]http://" .. target_escaped, replacement = "fetch('https://" .. proxy_domain},
    {pattern = "fetch%s*%(%s*['\"]//" .. target_escaped, replacement = "fetch('//" .. proxy_domain},
    
    -- www subdomain in fetch patterns
    {pattern = "fetch%s*%(%s*['\"]https://www%." .. target_escaped, replacement = "fetch('https://" .. proxy_domain},
    {pattern = "fetch%s*%(%s*['\"]http://www%." .. target_escaped, replacement = "fetch('https://" .. proxy_domain},
    {pattern = "fetch%s*%(%s*['\"]//www%." .. target_escaped, replacement = "fetch('//" .. proxy_domain},
    
    -- Axios patterns
    {pattern = "axios%.get%s*%(%s*['\"]https://" .. target_escaped, replacement = "axios.get('https://" .. proxy_domain},
    {pattern = "axios%.post%s*%(%s*['\"]https://" .. target_escaped, replacement = "axios.post('https://" .. proxy_domain},
    
    -- www subdomain in axios patterns
    {pattern = "axios%.get%s*%(%s*['\"]https://www%." .. target_escaped, replacement = "axios.get('https://" .. proxy_domain},
    {pattern = "axios%.post%s*%(%s*['\"]https://www%." .. target_escaped, replacement = "axios.post('https://" .. proxy_domain},
    
    -- Window location patterns
    {pattern = "window%.location%s*=%s*['\"]https://" .. target_escaped, replacement = "window.location = '" .. proxy_domain},
    {pattern = "location%.href%s*=%s*['\"]https://" .. target_escaped, replacement = "location.href = '" .. proxy_domain},
    
    -- www subdomain in location patterns
    {pattern = "window%.location%s*=%s*['\"]https://www%." .. target_escaped, replacement = "window.location = '" .. proxy_domain},
    {pattern = "location%.href%s*=%s*['\"]https://www%." .. target_escaped, replacement = "location.href = '" .. proxy_domain},
    
    -- JSON patterns
    {pattern = '"url"%s*:%s*"https://' .. target_escaped, replacement = '"url": "https://' .. proxy_domain},
    {pattern = '"api"%s*:%s*"https://' .. target_escaped, replacement = '"api": "https://' .. proxy_domain},
    {pattern = '"base"%s*:%s*"https://' .. target_escaped, replacement = '"base": "https://' .. proxy_domain},
    
    -- www subdomain in JSON patterns
    {pattern = '"url"%s*:%s*"https://www%." .. target_escaped, replacement = '"url": "https://' .. proxy_domain},
    {pattern = '"api"%s*:%s*"https://www%." .. target_escaped, replacement = '"api": "https://' .. proxy_domain},
    {pattern = '"base"%s*:%s*"https://www%." .. target_escaped, replacement = '"base": "https://' .. proxy_domain},
    
    -- XML patterns
    {pattern = "href%s*=%s*['\"]https://" .. target_escaped, replacement = "href='" .. proxy_domain},
    {pattern = "src%s*=%s*['\"]https://" .. target_escaped, replacement = "src='" .. proxy_domain},
    
    -- www subdomain in XML patterns
    {pattern = "href%s*=%s*['\"]https://www%." .. target_escaped, replacement = "href='" .. proxy_domain},
    {pattern = "src%s*=%s*['\"]https://www%." .. target_escaped, replacement = "src='" .. proxy_domain}
}

-- Content types that should be processed for URL replacement
local TEXT_CONTENT_TYPES = {
    "text/html", "text/plain", "text/css", "text/javascript", "application/javascript",
    "application/x-javascript", "text/xml", "application/xml", "application/json",
    "text/json", "application/ld+json", "text/yaml", "application/yaml",
    "text/markdown", "application/rss+xml", "application/atom+xml",
    "text/typescript", "application/typescript", "text/ts", "application/ts",
    "text/jsx", "application/jsx", "text/tsx", "application/tsx"
}

-- Function to check if content type should be processed
local function should_process_content_type(content_type)
    if not content_type then
        return false
    end
    
    content_type = string.lower(content_type)
    
    for _, allowed_type in ipairs(TEXT_CONTENT_TYPES) do
        if content_type:find(allowed_type, 1, true) then
            return true
        end
    end
    
    return false
end

-- Function to replace URLs in text content
local function replace_urls_in_content(content)
    if not content or type(content) ~= "string" then
        return content
    end
    
    local modified = false
    local result = content
    
    for _, pattern_data in ipairs(URL_PATTERNS) do
        local new_result = string.gsub(result, pattern_data.pattern, pattern_data.replacement)
        if new_result ~= result then
            result = new_result
            modified = true
        end
    end
    
    if modified then
        ngx.log(ngx.INFO, "URLs replaced in content for domain rewrite")
    end
    
    return result
end

-- Main body filter function with request-scoped buffering
local function filter_body()
    local content_type = ngx.header.content_type
    if not should_process_content_type(content_type) then
        return
    end
    
    -- Get the response body chunk
    local chunk = ngx.arg[1]
    if not chunk then
        return
    end
    
    -- Initialize request-scoped buffer if not exists
    if not ngx.ctx.body_buffer then
        ngx.ctx.body_buffer = ""
    end
    
    -- Accumulate chunks
    ngx.ctx.body_buffer = ngx.ctx.body_buffer .. chunk
    
    -- Process on last chunk
    if ngx.arg[2] then
        local processed_content = replace_urls_in_content(ngx.ctx.body_buffer)
        ngx.arg[1] = processed_content
        ngx.ctx.body_buffer = nil -- Clean up
    else
        -- Not the last chunk, don't output anything yet
        ngx.arg[1] = nil
    end
end

-- Execute with error handling
local ok, err = pcall(filter_body)
if not ok then
    ngx.log(ngx.ERR, "Error in body filter: ", err)
end 