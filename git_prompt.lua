local git_prompt = require('git_prompt_lib')

function git_prompt_filter()
    ps1 = git_prompt.git_ps1()
    if ps1 ~= "" then
        git_prompt = clink.prompt.value .. " (" .. ps1 .. ") "
        clink.prompt.value = git_prompt
    end

    return false
end

clink.prompt.register_filter(git_prompt_filter, 50)