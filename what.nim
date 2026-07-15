import std/[os, osproc, strutils, httpclient, json]

type
  Config = object
    api: string
    key: string
    model: string

# Retrieve and clean the man page text
proc getManPage(cmd: string): string =
  # Using 'man' piped through 'col -b' to strip backspace formatting and special characters
  let shellCmd = "man " & quoteShell(cmd) & " | col -b"
  let (output, exitCode) = execCmdEx(shellCmd)
  
  if exitCode != 0:
    echo "Error: Could not find or read the man page for '" & cmd & "'."
    echo "Make sure the command is installed and has a manual entry."
    quit(1)
  
  return output

# Parse the configuration file at ~/.config/what/what.conf
proc loadConfig(): Config =
  let confDir = getHomeDir() / ".config" / "what"
  let confPath = confDir / "what.conf"
  
  if not fileExists(confPath):
    echo "Error: Configuration file not found at " & confPath
    echo "\nPlease create the directory and file with the following format:"
    echo "mkdir -p " & confDir
    echo "cat <<EOF > " & confPath
    echo "API=https://api.openai.com/v1"
    echo "KEY=your-api-key-here"
    echo "MODEL=gpt-4o"
    echo "EOF"
    quit(1)

  var api, key, model: string
  for line in lines(confPath):
    let trimmed = line.strip()
    if trimmed.startsWith("#") or trimmed == "": 
      continue
    
    let parts = trimmed.split('=', 1)
    if parts.len == 2:
      let k = parts[0].strip().toUpperAscii()
      let v = parts[1].strip().strip(chars = {'"', '\''})
      case k
      of "API": api = v
      of "KEY": key = v
      of "MODEL": model = v
      else: discard

  if api == "" or key == "" or model == "":
    echo "Error: Configuration at '" & confPath & "' is missing required keys (API, KEY, or MODEL)."
    quit(1)

  return Config(api: api, key: key, model: model)

# Parse command line parameters manually
proc parseArgs(): tuple[cmd: string, instruction: string] =
  let params = commandLineParams()
  if params.len == 0:
    echo "Usage: what <command> [-i \"custom instructions/questions\"]"
    quit(0)

  var cmd = ""
  var instruction = ""
  var i = 0
  while i < params.len:
    let arg = params[i]
    if arg == "-i" or arg == "--instruction" or arg == "--input":
      if i + 1 < params.len:
        instruction = params[i+1]
        i += 2
      else:
        echo "Error: Missing value for instruction parameter " & arg
        quit(1)
    else:
      if cmd == "":
        cmd = arg
      i += 1

  if cmd == "":
    echo "Error: No command specified."
    echo "Usage: what <command> [-i \"custom instructions/questions\"]"
    quit(1)

  return (cmd, instruction)

# Query the OpenAI-compatible endpoint
proc queryAI(config: Config, manPage: string, command: string, instruction: string): string =
  let client = newHttpClient()
  client.headers = newHttpHeaders({
    "Content-Type": "application/json",
    "Authorization": "Bearer " & config.key
  })

  # Handle base URL vs direct completions endpoint
  var endpoint = config.api
  if not endpoint.endsWith("/chat/completions"):
    if endpoint.endsWith("/"):
      endpoint &= "chat/completions"
    else:
      endpoint &= "/chat/completions"

  # System/User Prompts
  let systemPrompt = "You are a concise command-line helper. Your job is to format and summarize man page entries into clear, practical markdown guides with highly actionable examples."
  
  # Limit input size to avoid excessive token usage on massive man pages
  var truncatedMan = manPage
  if truncatedMan.len > 100_000:
    truncatedMan = truncatedMan[0..100_000] & "\n... [truncated due to size] ..."

  var userPrompt = "Here is the raw man page text for the command '" & command & "':\n\n"
  userPrompt &= truncatedMan & "\n\n"
  userPrompt &= "Provide a succinct summary of this command, prioritizing the most common use-cases and associated flags. Show direct, practical examples."

  if instruction != "":
    userPrompt &= "\n\nAdditional Instruction/Question from user:\n" & instruction

  let jsonPayload = %*{
    "model": config.model,
    "messages": [
      {"role": "system", "content": systemPrompt},
      {"role": "user", "content": userPrompt}
    ]
  }

  try:
    let response = client.post(endpoint, $jsonPayload)
    if response.status != "200 OK":
      echo "Error: API call failed with status: ", response.status
      echo response.body
      quit(1)

    let responseJson = parseJson(response.body)
    return responseJson["choices"][0]["message"]["content"].getStr()
  except Exception as e:
    echo "An error occurred during the API request: ", e.msg
    quit(1)
  finally:
    client.close()

# Main Execution Flow
proc main() =
  let (command, instruction) = parseArgs()
  let config = loadConfig()
  
  echo "Fetching man page for '" & command & "'..."
  let manPage = getManPage(command)
  
  echo "Analyzing with " & config.model & "..."
  let summary = queryAI(config, manPage, command, instruction)
  
  echo "\n--- Summary for: " & command & " ---\n"
  echo summary

if isMainModule:
  main()
