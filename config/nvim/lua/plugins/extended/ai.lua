return {
  {
    "David-Kunz/gen.nvim",
    cmd = "Gen",
    opts = {
      model = "deepseek-coder",
      display_mode = "split", -- The display mode. Can be "float" or "split".
      show_prompt = true, -- Shows the Prompt submitted to Ollama.
      show_model = true, -- Displays which model you are using at the beginning of your chat session.
      no_auto_close = true, -- Never closes the window automatically.
      init = function(options) pcall(io.popen, "ollama serve > /dev/null 2>&1 &") end,
      -- Function to initialize Ollama
      command = "curl --silent --no-buffer -X POST http://localhost:11434/api/generate -d $body",
    },
    config = function(_, opts)
      require("gen").setup(opts)
      require("gen").prompts["Elaborate_Text"] = {
        prompt = "Elaborate the following text:\n$text",
        replace = true,
      }
      require("gen").prompts["Fix_Code"] = {
        prompt = "Fix the following code. Only ouput the result in format ```$filetype\n...\n```:\n```$filetype\n$text\n```",
        replace = true,
        extract = "```$filetype\n(.-)```",
      }
      require("gen").prompts["DevOps me!"] = {
        prompt = "You are a senior devops engineer, acting as an assistant. You offer help with cloud technologies like: Terraform, AWS, kubernetes, python. You answer with code examples when possible. $input:\n$text",
        replace = true,
      }

      local icn = {
        Chat = "", --     
        Test = "", --    
        Regex = "", --   
        Comment = "", --  
        Code = "", --   
        Text = "", --   
        Items = "", --    
        Swap = "", -- 
        Keep = "", --  
        into = "", --  
      }

      require("gen").prompts = {
        [icn.Chat .. " Ask about given context " .. icn.Keep] = {
          prompt = "Regarding the following text, $input:\n$text",
          model = "mistral",
        },
        [icn.Chat .. " Chat about anything " .. icn.Keep] = {
          prompt = "$input",
          model = "mistral",
        },
        [icn.Regex .. " Regex create " .. icn.Swap] = {
          prompt = "Create a regular expression for $filetype language that matches the following pattern:\n```$filetype\n$text\n```",
          replace = true,
          no_auto_close = false,
          extract = "```$filetype\n(.-)```",
          model = "deepseek-coder",
        },
        [icn.Regex .. " Regex explain " .. icn.Keep] = {
          prompt = "Explain the following regular expression:\n```$filetype\n$text\n```",
          extract = "```$filetype\n(.-)```",
          model = "deepseek-coder",
        },
        [icn.Comment .. " Code " .. icn.into .. " JSDoc " .. icn.Keep] = {
          prompt = "Write JSDoc comments for the following $filetype code:\n```$filetype\n$text\n```",
          model = "deepseek-coder",
        },
        [icn.Comment .. " JSDoc " .. icn.into .. " Code " .. icn.Keep] = {
          prompt = "Read the following comment and create the $filetype code below it:\n```$filetype\n$text\n```",
          extract = "```$filetype\n(.-)```",
          model = "deepseek-coder",
        },
        [icn.Test .. " Unit Test add missing (React/Jest) " .. icn.Keep] = {
          prompt = "Read the following $filetype code that includes some unit tests inside the 'describe' function. We are using Jest with React testing library, and the main component is reused by the tests via the customRender function. Detect if we have any missing unit tests and create them.\n```$filetype\n$text\n```",
          extract = "```$filetype\n(.-)```",
          model = "deepseek-coder",
        },
        [icn.Code .. " Code suggestions " .. icn.Keep] = {
          prompt = "Review the following $filetype code and make concise suggestions:\n```$filetype\n$text\n```",
          model = "deepseek-coder",
        },
        [icn.Code .. " Explain code " .. icn.Keep] = {
          prompt = "Explain the following $filetype code in a very concise way:\n```$filetype\n$text\n```",
          model = "deepseek-coder",
        },
        [icn.Code .. " Fix code " .. icn.Swap] = {
          prompt = "Fix the following $filetype code:\n```$filetype\n$text\n```",
          replace = true,
          no_auto_close = false,
          extract = "```$filetype\n(.-)```",
          model = "deepseek-coder",
        },
        [icn.Items .. " Text " .. icn.into .. " List of items " .. icn.Swap] = {
          prompt = "Convert the following text, except for the code blocks, into a markdown list of items without additional quotes around it:\n$text",
          replace = true,
          no_auto_close = false,
          model = "mistral",
        },
        [icn.Items .. " List of items " .. icn.into .. " Text " .. icn.Swap] = {
          prompt = "Convert the following list of items into a block of text, without additional quotes around it. Modify the resulting text if needed to use better wording.\n$text",
          replace = true,
          no_auto_close = false,
          model = "mistral",
        },
        [icn.Text .. " Fix Grammar / Syntax in text " .. icn.Swap] = {
          prompt = "Fix the grammar and syntax in the following text, except for the code blocks, and without additional quotes around it:\n$text",
          replace = true,
          no_auto_close = false,
          model = "mistral",
        },
        [icn.Text .. " Reword text " .. icn.Swap] = {
          prompt = "Modify the following text, except for the code blocks, to use better wording, and without additional quotes around it:\n$text",
          replace = true,
          no_auto_close = false,
          model = "mistral",
        },
        [icn.Text .. " Simplify text " .. icn.Swap] = {
          prompt = "Modify the following text, except for the code blocks, to make it as simple and concise as possible and without additional quotes around it:\n$text",
          replace = true,
          no_auto_close = false,
          model = "mistral",
        },
        [icn.Text .. " Summarize text " .. icn.Keep] = {
          prompt = "Summarize the following text, except for the code blocks, without additional quotes around it:\n$text",
          model = "mistral",
        },
      }
    end,
  },
}
