# what
This little Nim tool just takes a man page (from the command itself, make sure you have `man` installed) and routes it into an AI of your choosing.

## Usage
Like so:
`what tar`
To simply summarize the manpage into a much simpler usage guide rather than going into the verbose specifics like `nan` does.

You might want specific instructions. You can add them to the prompt using `-i`:
`what tar -i "How do I extract only specific files from an archive?"`

To configure it, create a file at `~/.config/what/what.conf` containing these three key=value pairs:
```
API=[the URl of the OpenAi-compatible API endpoint you want to use]
KEY=[your api key]
MODEL=[the model to use]
```

That's it. That's literally all this tool does.

### Requirements
I think you need these two packages:
`openssl` and `man`. Pretty sure. Maybe. I could be wrong.

## Disclaimers

It doesn't render markdown so you just get to read it with \* and \` everywhere. Sorry.
The prompt is baked into the tool but if you wanna just modify the prompt and build it yourself you can, or just add -i "Don't use markdown."

**I one-shotted this with Gemini. No guarantees of efficiency. I did not make this, Gemini did.**
