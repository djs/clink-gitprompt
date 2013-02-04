--
-- Copyright (c) 2013 Dan Savilonis
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function file_exists(name)
    --http://stackoverflow.com/questions/4990990/lua-check-if-a-file-exists
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end

function directory_exists(path)
    return clink.is_dir(path)
end

function file_contents(name)
    local file = io.open(name, "r")
    local data = file:read("*a")
    local rc = {file:close()}

    return data
end

function gitdir()
    local file = io.popen("git rev-parse --git-dir 2>nul")
    local output = file:read('*all')
    local rc = {file:close()}
    return trim(output)
end

function ingitdir()
    local file = io.popen("git rev-parse --is-inside-git-dir 2>nul")
    local output = trim(file:read('*all'))
    local rc = {file:close()}
    if output == "true" then
        return true
    else
        return false
    end
end

function inbarerepo()
    local file = io.popen("git rev-parse --is-bare-repository 2>nul")
    local output = file:read('*all')
    local output = trim(file:read('*all'))
    local rc = {file:close()}
    if output == "true" then
        return true
    else
        return false
    end
end

function insideworktree()
    local file = io.popen("git rev-parse --is-inside-work-tree 2>nul")
    local output = trim(file:read('*all'))
    local rc = {file:close()}
    if output == "true" then
        return true
    else
        return false
    end
end

function gitsymbolicref(ref)
    local file = io.popen("git symbolic-ref " .. ref .. " 2>nul")
    local output = file:read('*all')
    local rc = {file:close()}
    return trim(output)
end

function git_ps1()
    local pcmode = false
    local detached = false

    local g = gitdir()
    if not g then
        return ""
    end

    local r = ""
    local b = ""

    if file_exists(g .. "/rebase-merge/interactive") then
        r = "|REBASE-i"
        b = trim(file_contents(g .. "/rebase-merge/head-name"))
    elseif directory_exists(g .. "/rebase-merge") then
        r = "|REBASE-m"
        b = trim(file_contents(g .. "/rebase-merge/head-name"))
    else
        if directory_exists(g .. "/rebase-apply") then
            if file_exists(g .. "/rebase-apply/rebasing") then
                r = "|REBASE"
            elseif file_exists(g .. "/rebase-apply/applying") then
                r = "|AM"
            else
                r = "|AM/REBASE"
            end
        elseif file_exists(g .. "/MERGE_HEAD") then
            r = "|MERGING"
        elseif file_exists(g .. "/CHERRY_PICK_HEAD") then
            r = "|CHERRY-PICKING"
        elseif file_exists(g .. "/BISECT_LOG") then
            r = "|BISECTING"
        end

        b = gitsymbolicref("HEAD")
        if not b then
            detached = true
            b = "detached"
        end
    end

    local w = ""
    local i = ""
    local s = ""
    local u = ""
    local c = ""
    local p = ""

    if ingitdir() then
        if inbarerepo() then
            c = "BARE:"
        else
            b = "GIT_DIR!"
        end
    elseif insideworktree() then
        -- nada
    end

    local f = w..i..s..u

    b = string.gsub(b, "^refs/heads/", "")
    local prompt = c..b..f..r..p
    return prompt
end

function git_prompt_filter()
    ps1 = git_ps1()
    if ps1 ~= "" then
        git_prompt = clink.prompt.value .. " (" .. ps1 .. ") "
        clink.prompt.value = git_prompt
    end

    return false
end

clink.prompt.register_filter(git_prompt_filter, 50)
--print(git_ps1())
