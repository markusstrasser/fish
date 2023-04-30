# thx to https://github.com/mduvall/config/
# The sfix function takes up to two optional arguments:
# 1. The number of last commands and their outputs to include in the prompt (default is 1).
# 2. An optional text that comes at the beginning of the sgpt prompt.

#!TODO separate functions into files and give them more arguments

function make_git
  set -l dir (pwd)
  set -l repo_name (basename $dir)

  # Create GitHub repo
  set -l access_token $GITHUB_ACCESS_TOKEN
  set -l user $GITHUB_USERNAME
  set -l url "https://api.github.com/user/repos"
  curl -H "Authorization: token $access_token" -d "{\"name\":\"$repo_name\"}" $url > /dev/null 2>&1

  # Initialize git, add all files, commit and push to GitHub
  git init
  git add .
  git commit -m "Initial commit"
  set -l repo_url "git@github.com:$user/$repo_name.git"
  set -l branch_name "main" # or "master"
  
  git remote add origin $repo_url
  git push -u origin $branch_name

  printf "Successfully created and pushed new project '$repo_name' to GitHub!\n"
  printf "Directory: $dir\n"
  printf "GitHub URL: $repo_url\n"
end


#! WIP ... needs better formulation
function nproj
  set -l name $argv[1]
  set -l dir (pwd)/$name

  # Create directory and cd into it
  mkdir $dir
  cd $dir

  # Initialize git and add README.md
  git init
  touch README.md
  git add README.md
  git commit -m "Initial commit"

  # Create GitHub repo
  set -l access_token $GITHUB_ACCESS_TOKEN
  set -l user $GITHUB_USERNAME
  set -l url "https://api.github.com/user/repos"
  curl -H "Authorization: token $access_token" -d "{\"name\":\"$name\"}" $url > /dev/null 2>&1
 
  printf "$(tput setaf 2)Successfully created and pushed new project '$name' to GitHub!$(tput sgr0)\n"

  # Push to GitHub
  set -l repo_url "git@github.com:$user/$name.git"
  git remote add origin $repo_url
  git push -u origin main

  # Log helpful messages
  printf "$(tput setaf 2)Directory: $dir$(tput sgr0)\n"
  printf "$(tput setaf 2)GitHub URL: $repo_url$(tput sgr0)\n"
end




function sfix
  set -l n 1
  if test (count $argv) -gt 0
      set n $argv[1]
  end

  set -l commands_outputs ""
  for i in (seq $n)
      set -l command (history --max=$i --show-time=false | string trim | tail -n 1)
      set -l command_output (eval $command 2>&1)
      set commands_outputs "$commands_outputs$command $command_output "
  end

  sgpt --shell $commands_outputs
end


function sfix_old
  set -l first_arg $argv[1]
  set -l second_arg $argv[2]

  set -l os_name (uname)
  set -l os_version (sw_vers -productVersion)
  set -l brew_packages (brew list)
  set -l shell_environment (echo $SHELL)

  set -l system_info "[Current System: $os_name $os_version, {brew packages: $brew_packages}, {current shell environment: $shell_environment}]"

  if test (count $argv) -gt 0; and string match -r -- "^-?[0-9]+\\b" "$argv[1]"
      set first_arg $argv[1]
  else
      set first_arg 1
  end

  if test (count $argv) -gt 1; and not string match -r -- "^-?[0-9]+\\b" "$argv[2]"
      set second_arg $argv[2]
  else
      set second_arg ""
  end

  set -l last_n_commands_output (rl -$first_arg | string join \n)
  echo $second_arg$last_n_commands_output$system_info | sgpt --shell "{context}"
end


function grm
find . -type f ! ( -name '*.tmp' -o -name 'temp*' ) -exec rm -i -v {} +
end

function subl --description 'Open Sublime Text'
  if test -d "/Applications/Sublime Text.app"
    "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" $argv
  else if test -d "/Applications/Sublime Text 2.app"
    "/Applications/Sublime Text 2.app/Contents/SharedSupport/bin/subl" $argv
  else if test -x "/opt/sublime_text/sublime_text"
    "/opt/sublime_text/sublime_text" $argv
  else if test -x "/opt/sublime_text_3/sublime_text"
    "/opt/sublime_text_3/sublime_text" $argv
  else
    echo "No Sublime Text installation found"
  end
end

function fuck
  eval (thefuck $history[1]); and commandline -t ""; and commandline -f repaint
end

function rl
    source ~/.config/fish/config.fish
end

function killf
  if ps -ef | sed 1d | fzf -m | awk '{print $2}' > $TMPDIR/fzf.result
    kill -9 (cat $TMPDIR/fzf.result)
  end
end

function clone --description "clone something, cd into it. install it."
    git clone --depth=1 $argv[1]
    cd (basename $argv[1] | sed 's/.git$//')
    yarn install
end

function notif --description "make a macos notification that the prev command is done running"
  #  osascript -e 'display notification "hello world!" with title "Greeting" sound name "Submarine"'
  osascript \
    -e "on run(argv)" \
    -e "return display notification item 1 of argv with title \"command done\" sound name \"Submarine\"" \
    -e "end" \
    -- "$history[1]"
end

function all_binaries_in_path --description "list all binaries available in \$PATH, even if theres conflicts"
  # based on https://unix.stackexchange.com/a/120790/110766 but tweaked to work on mac. and then made it faster.
  find -L $PATH -maxdepth 1 -perm +111 -type f
  #gfind -L $PATH -maxdepth 1 -executable -type f # shrug. probably can delete this.
end

function stab --description "stabalize a video"
  set -l vid $argv[1]
  ffmpeg -i "$vid" -vf vidstabdetect=stepsize=32:result="$vid.trf" -f null -; 
  ffmpeg -i "$vid" -b:v 5700K -vf vidstabtransform=interpol=bicubic:input="$vid.trf" "$vid.mkv";  # :optzoom=2 seems nice in theory but i dont love it. kinda want a combo of 1 and 2. (dont zoom in past the static zoom level, but adaptively zoom out to full when possible)
  ffmpeg -i "$vid" -i "$vid.mkv" -b:v 3000K -filter_complex hstack "$vid.stack.mkv"
  # vid=Dalton1990/Paultakingusaroundthehouseagai ffmpeg -i "$vid.mp4" -i "$vid.mkv" -b:v 3000K -filter_complex hstack $HOME/Movies/"Paultakingusaroundthehouseagai.stack.mkv"
  command rm $vid.trf
end


function md --wraps mkdir -d "Create a directory and cd into it"
  command mkdir -p $argv
  if test $status = 0
    switch $argv[(count $argv)]
      case '-*'
      case '*'
        cd $argv[(count $argv)]
        return
    end
  end
end

function gz --d "Get the gzipped size"
  printf "%-20s %12s\n"  "compression method"  "bytes"
  printf "%-20s %'12.0f\n"  "original"         (cat "$argv[1]" | wc -c)
  
  # -5 is what GH pages uses, dunno about others
  # fwiw --no-name is equivalent to catting into gzip
  printf "%-20s %'12.0f\n"  "gzipped (-5)"     (cat "$argv[1]" | gzip -5 -c | wc -c)
  printf "%-20s %'12.0f\n"  "gzipped (--best)" (cat "$argv[1]" | gzip --best -c | wc -c)
  
  # brew install brotli to get these as well
  if hash brotli
  # googlenews uses about -5, walmart serves --best 
  printf "%-20s %'12.0f\n"  "brotli (-q 5)"    (cat "$argv[1]" | brotli -c --quality=5 | wc -c)
  printf "%-20s %'12.0f\n"  "brotli (--best)"  (cat "$argv[1]" | brotli -c --best | wc -c)
  end
end

function sudo!!
    eval sudo $history[1]
end


# `shellswitch [bash|zsh|fish]`
function shellswitch
	chsh -s (brew --prefix)/bin/$argv
end

function upgradeyarn
  curl -o- -L https://yarnpkg.com/install.sh | bash
end


# function fuck
#   # Get the previous command from history.
#   set -l previous_command $history[1]

#   # Get the suggested correction from thefuck.
#   set -l suggested_correction (thefuck $previous_command)

#   # Check if a correction was suggested.
#   if test -n "$suggested_correction"
#       # Evaluate the suggested correction.
#       eval $suggested_correction

#       # If the suggested correction was successful, remove the previous command from history.
#       if test $status -eq 0
#           history --delete $previous_command
#       end
#   end
# end


# function fuck -d 'Correct your previous console command'
#     set -l exit_code $status
#     set -l eval_script (mktemp 2>/dev/null ; or mktemp -t 'thefuck')
#     set -l fucked_up_commandd $history[1]
#     thefuck $fucked_up_commandd > $eval_script
#     . $eval_script
#     rm $eval_script
#     if test $exit_code -ne 0
#         history --delete $fucked_up_commandd
#     end
# end

# requires my excellent `npm install -g statikk`
function server -d 'Start a HTTP server in the current dir, optionally specifying the port'    
    # arg can either be port number or extra args to statikk
    if test $argv[1]
      if string match -qr '^-?[0-9]+(\.?[0-9]*)?$' -- "$argv[1]"
        echo $argv[1] is a number
        set port $argv[1]
        statikk --open --port "$port"
      else
        echo "not a number"
        statikk --open $argv[1]
      end
        
    else
        statikk --open
    end
end


function emptytrash -d 'Empty the Trash on all mounted volumes and the main HDD. then clear the useless sleepimage'
    sudo rm -rfv "/Volumes/*/.Trashes"
    grm -rf "~/.Trash/*"
    rm -rfv "/Users/paulirish/Library/Application Support/stremio/Cache"
    rm -rfv "/Users/paulirish/Library/Application Support/stremio/stremio-cache"
    rm -rfv "~/Library/Application Support/Spotify/PersistentCache/Update/*.tbz"
    rm -rfv ~/Library/Caches/com.spotify.client/Data
    rm -rfv ~/Library/Caches/Firefox/Profiles/98ne80k7.dev-edition-default/cache2
end

function conda -d 'lazy initialize conda'
  functions --erase conda
  eval /opt/miniconda3/bin/conda "shell.fish" "hook" | source
  # There's some opportunity to use `psub` but I don't really understand it.
  conda $argv
end

# NVM doesnt support fish and its stupid to try to make it work there.
