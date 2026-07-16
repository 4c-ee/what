# what
This little Nim tool just takes a man page (from the command itself, make sure you have `man` installed) and routes it into an AI of your choosing for summarization, because I'm not good at reading

## Usage
Like so:

`what tar`

To simply summarize the manpage for `tar` into a much simpler usage guide rather than going into the verbose specifics like `man` does.

You might want to instruct the AI on a specific topic. You can add them to the prompt using `-i`:

`what tar -i "How do I extract only specific files from an archive?"`

By default, it will save and load responses for each command (and for special instructions) so you're not using up tokens asking it for the same information every time.
To create a new response for a cached command, add the `-r` (`--redo`) flag.

Command responses are stored in `~/.cache/what`, so you can also edit cached responses if you want, or write them yourself.

(this technically also means that this kind of works as another `cat` as well because it does print the content of whatever file you want as long as it's in that folder...)

To configure the tool for usage, create a file at `~/.config/what/what.conf` containing these three key=value pairs:
```
API=[the URl of the OpenAI-compatible API endpoint you want to use]
KEY=[your api key]
MODEL=[the model to use]
```

### Requirements
I think you need these two packages: `openssl` and `man`. Pretty sure. Maybe. I could be wrong.

## Disclaimers

It doesn't render markdown so you just get to read it with \* and \` and \# everywhere. Sorry.

The prompt is baked into the tool but if you wanna just modify the prompt and build it yourself you can.

**I one(-ish)-shotted this with Gemini. I did not make this, Gemini did.**
